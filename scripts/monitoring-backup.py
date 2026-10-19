#!/usr/bin/env python3
"""Create encrypted Grafana/Kuma backups without stopping either service."""
import argparse
from contextlib import closing
from datetime import datetime, timezone
import os
from pathlib import Path
import sqlite3
import subprocess
import tarfile
import tempfile


def snapshot(source, destination):
    # mode=ro prevents a missing source from becoming an empty new database.
    with closing(sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True)) as src:
        with closing(sqlite3.connect(destination)) as dst:
            src.backup(dst, pages=256, sleep=0.1)
            if dst.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
                raise RuntimeError(f"Database integrity check failed: {source.name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--grafana-dir", type=Path, required=True)
    parser.add_argument("--grafana-db", type=Path, required=True)
    parser.add_argument("--grafana-settings", type=Path, required=True)
    parser.add_argument("--kuma-dir", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--recipient", required=True)
    args = parser.parse_args()
    os.umask(0o077)
    databases = [(args.grafana_db, "grafana/data/grafana.db"),
                 (args.kuma_dir / "kuma.db", "uptime-kuma/kuma.db")]
    excluded = {str(path.resolve()) + suffix for path, _ in databases
                for suffix in ("", "-wal", "-shm", "-journal")}

    def walk_error(error):
        raise error

    args.destination.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    output = args.destination / f"monitoring-{stamp}.tar.gz.age"
    with tempfile.TemporaryDirectory(prefix="monitoring-backup-") as work:
        work = Path(work)
        for index, (source, _) in enumerate(databases):
            snapshot(source, work / f"{index}.db")
        archive = work / "monitoring.tar.gz"
        with tarfile.open(archive, "w:gz") as tar:
            for directory, label in ((args.grafana_dir, "grafana"),
                                     (args.kuma_dir, "uptime-kuma")):
                # Do not follow symlinks into Nix store packages.
                for base, dirs, files in os.walk(directory, onerror=walk_error):
                    for name in dirs + files:
                        path = Path(base) / name
                        if str(path.resolve()) in excluded or path.is_socket():
                            continue
                        tar.add(path, arcname=str(Path(label) / path.relative_to(directory)),
                                recursive=False)
            for index, (_, label) in enumerate(databases):
                tar.add(work / f"{index}.db", arcname=label)
            tar.add(args.grafana_settings, arcname="grafana-settings.json")
        # Publish only complete encrypted files; never put plaintext on the NAS.
        with tempfile.NamedTemporaryFile(dir=args.destination, prefix=".monitoring-", delete=False) as pending:
            temporary = Path(pending.name)
            try:
                subprocess.run(["age", "-r", args.recipient, str(archive)], stdout=pending, check=True)
                pending.flush()
                os.fsync(pending.fileno())
                temporary.rename(output)
            finally:
                temporary.unlink(missing_ok=True)
    print(f"Encrypted monitoring backup saved: {output.name}")


if __name__ == "__main__":
    main()

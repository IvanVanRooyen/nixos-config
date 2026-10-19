# Monitoring and alerting

Grafana and Uptime Kuma keep application configuration in SQLite. The Nix module
starts the services, but their existing alert rules, policies, monitors and
notification settings are managed through their applications.

## Backups

After deploying `modules/monitoring.nix`, `monitoring-backup.timer` runs daily at
03:15 Brisbane time, with up to 10 minutes of jitter and catch-up after downtime.
It requires the real `mnt-nas.mount` unit, so a failed NAS mount fails the job
rather than writing backups onto the server's local mount directory.

The backup uses SQLite's online backup API and checks the resulting databases for
integrity. It preserves Grafana's state directory, rendered settings and Kuma's
data directory, substituting consistent database snapshots for the live database,
WAL and SHM files. Services remain running. Files such as uploaded images and
plugins are copied during the run; they are not an application-wide atomic snapshot.

Archives are encrypted with age to the existing sops recipient, then saved as
`/mnt/nas/Backups/monitoring/monitoring-<UTC timestamp>.tar.gz.age`. Plaintext stays
in the service's private local temporary directory. A failed encryption never
publishes a completed backup. Archives are retained until manually reviewed and
removed; no automatic deletion is configured.

Deploy and perform the first real backup as the server administrator:

```sh
sudo nixos-rebuild switch -I nixos-config=/home/ivanvr/nixos-config
sudo systemctl start monitoring-backup.service
systemctl status monitoring-backup.service --no-pager
systemctl list-timers monitoring-backup.timer
```

The timer and backup have not been deployed or tested against the real service
databases by Codex. The script passed a fixture round-trip with live WAL commits,
asset files and symlinks, plus missing-database and encryption-failure checks.
Nix evaluation of the generated service script passed.

The databases include user accounts and notification credentials, so keep the
archives encrypted. Decryption needs the existing age identity, normally
`/var/lib/sops-nix/key.txt` or the user's `~/.config/sops/age/keys.txt`. Recovery
also requires the Nix configuration and encrypted sops secrets; this archive is
not a backup of all services, Prometheus metric history, or the entire server.

## Recovery check and restoration

Use `nix-shell -p age sqlite` if the tools are not in your shell. Decrypt a selected
archive into a private temporary directory, inspect its file list, extract it,
and run `sqlite3 <database> 'PRAGMA integrity_check;'` against both databases.
Confirm expected dashboards/alert rules and monitor counts before restoring.
Retain an independently recoverable copy of the age identity.

For a real restore, stop `grafana.service` and `uptime-kuma.service` first. Preserve
their current data and ownership for rollback. Restore the Grafana database to
`/var/lib/grafana/data/grafana.db`, Kuma's to `/var/lib/uptime-kuma/kuma.db`, and any
needed assets to their original directories. Ensure the files retain the live
service directory's owner/group rather than the root-owned snapshot metadata;
Kuma uses a dynamic systemd user. Move aside stale `-wal` and `-shm` files from the
old databases while services are stopped. Reconcile the archived
`grafana-settings.json` with the Nix module, including the Grafana encryption key,
and restore sops secrets from the encrypted configuration if needed. Start the
services, check health and rule/monitor counts, then verify notifications with an
explicit test. Restoring a database also restores any accounts or tokens in it.

## Alert review pending authenticated access

On 2026-10-19 the Proxmox temperature sensor reported 76°C, a 24-hour peak of
85.25°C and mean of approximately 62°C. Bridge logs showed repeated firing and
resolution of the 70°C alert. This supports reviewing pending/recovery timing;
it does not establish a safe hardware threshold. Inspect the actual rule and
sensor history before applying a change. Preserve the current rule first.

Grafana supports pending periods, recovery thresholds and a keep-firing period.
Review those settings and notification repeat intervals together. The existing
temperature threshold has not been changed.

References:

- https://sqlite.org/backup.html
- https://grafana.com/docs/grafana/latest/alerting/alerting-rules/create-grafana-managed-rule/
- https://grafana.com/docs/grafana/latest/administration/service-accounts/
- https://grafana.com/docs/grafana/latest/alerting/set-up/provision-alerting-resources/http-api-provisioning/

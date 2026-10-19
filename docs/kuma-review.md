# Uptime Kuma review

Reviewed 2026-10-19, approximately 14:13 Brisbane time, through the authenticated
Socket.IO API of installed Kuma 1.23.17. Collection was read-only. No monitor
settings changed, notification tests sent, or backup schedules changed.

## Timeout correction applied

Later on 2026-10-19, Ivan authorized the explicit-timeout workaround. All nine
HTTP monitors were updated through Kuma's API to 20 seconds and read back for
verification. Full monitor objects were compared before and after: every other
field remained unchanged, including 60-second polling/retry intervals, three
retries and notification assignments. The two TCP monitors were unchanged.
Independent heartbeat-history collection confirmed fresh successful checks for
all 11 monitors after the update. The current credential-free inventory in
`monitoring/kuma-monitors.json` reflects the corrected settings.

The service stayed running; the API restarts each edited monitor's check loop as
part of applying settings. No NixOS rebuild or systemd service restart was needed.
No notification test was sent. The findings below describe the original review;
the zero-timeout finding is now mitigated for all existing HTTP monitors.

## Confirmed configuration

All 11 monitors are enabled, currently up, and outside maintenance. Each uses a
60-second polling interval, a 60-second retry interval and three retries. All are
assigned notification ID 1, the active/default Twilio SMS provider. Resend interval
is zero, so ongoing outages do not generate periodic reminder messages.

| Monitor | Target | Check |
|---|---|---|
| Plex | `http://localhost:32400/web` | HTTP GET |
| Audiobookshelf | `http://localhost:13378/` | HTTP GET |
| Immich | `http://localhost:2283/` | HTTP GET |
| Overseerr | `http://localhost:5055/` | HTTP GET |
| qBittorrent | `http://localhost:8080/` | HTTP GET |
| Grafana | `http://localhost:3000/` | HTTP GET |
| Prometheus | `http://localhost:9090/` | HTTP GET |
| Firefly III | `http://localhost:8084/` | HTTP GET |
| BookStack | `http://localhost:8086/` | HTTP GET |
| PostgreSQL | `localhost:5432` | TCP connection |
| MariaDB | `localhost:3306` | TCP connection |

HTTP monitors accept status 200–399, allow up to ten redirects, and do not use
keyword/body validation. TLS verification is not disabled. General settings show
Australia/Brisbane timezone and 180 days of data retention.

The latest 100 heartbeats per monitor (1,100 total, approximately 100 minutes)
were all up. Each monitor's important-event history returned only its initial
up event on October 18, with no recorded down/recovery events. Older journal
entries show two pending BookStack DNS failures and one pending Immich check
around service restart. These were not sustained outages in the returned history.

## Findings and proposed improvements

1. **Explicit HTTP timeout (now corrected).** At review, every monitor stored timeout zero. The
   installed `server/model/monitor.js` zero-timeout fallback assigns
   `interval * 1000 * 0.8` to a field subsequently multiplied by 1000 for Axios.
   At a 60-second interval this gives a 48,000-second HTTP timeout (13h20m), with
   the abort signal ten seconds later. There is no shorter HTTP timeout cap in
   the reviewed path. An isolated follow-up test loaded this exact installed
   Monitor class, with database/notification services stubbed, and made requests
   through its installed Axios to a temporary loopback server that accepted
   connections without responding. Zero passed 48,000,000 ms to Axios and stayed
   pending until a test-only watchdog cancelled it at 2.203 seconds. An explicit
   one-second timeout failed normally at 1.006 seconds. This confirms the request
   timeout path without disrupting any production service; the test did not
   wait 13 hours or demonstrate an actual production outage.
   The nine HTTP monitors were subsequently set to an explicit 20 seconds. TCP
   monitors use a separate helper and do not pass this field to that helper.
2. **Checks mainly prove frontend availability.** Login/static pages can remain
   available while backend functionality fails. Independently verified HTTP 200
   responses at Grafana `/api/health` (database OK), Prometheus `/-/ready`, and
   Immich `/api/server/ping` (pong). Those are candidates for stronger checks;
   readiness/ping still does not prove every application feature works. Database
   port checks confirm listeners, not authenticated queries.
3. **BookStack mixes local and external availability.** Its local root redirects
   to `https://wiki.ivanvanrooyen.com/login`. A request using Kuma's user-agent
   successfully followed that redirect and received HTTP 200. An earlier generic
   Python-user-agent probe received HTTPError; this did not reproduce a Kuma
   outage. The check depends on public DNS/tunnel routing despite starting at
   localhost. Decide whether it should deliberately test external access or a
   local health endpoint, and label it accordingly. No replacement local
   BookStack health endpoint was verified in this review.
4. **Coverage gaps.** Enabled NixOS services Jellyfin, Radarr, Sonarr and Prowlarr
   have no Kuma monitors in this inventory. Grafana covers host/Proxmox metrics;
   that does not establish these applications' HTTP health. UptimeRobot's
   external coverage has not been inspected, so duplication or gaps there
   cannot yet be concluded. Monitoring on this host also cannot send alerts
   while the entire host is offline; independent external coverage matters.
5. **SMS delivery remains untested.** Notification assignments are correct and
   recovery notifications are supported by the installed provider path. The
   returned history contains no down/recovery incident to establish delivery.
   No SMS was sent and no service was stopped during the review. A controlled
   notification test would confirm provider submission; phone receipt needs
   user confirmation. Zero reminder interval is a deliberate behavior to
   retain or change based on preference, not automatically a fault.

## Configuration preservation

`monitoring/kuma-monitors.json` is a credential-free review inventory of monitor
parameters, notification metadata and selected general settings. It is not an
importable Kuma backup: provider secrets, authentication fields, advanced monitor
fields and historical data are omitted. No session token was saved in the report
or repository. Full restoration still needs an encrypted configuration/database
backup or recreated settings and provider credentials. The daily backup frequency
remains undecided; no backup deployment is part of this review.

## Source for timeout behavior

The installed code was checked against the upstream version:
https://github.com/louislam/uptime-kuma/blob/1.23.17/server/model/monitor.js

An independent upstream report documents the same zero-timeout unit error in
version 2.4.0 (the local test above specifically checks installed 1.23.17):
https://github.com/louislam/uptime-kuma/issues/7656

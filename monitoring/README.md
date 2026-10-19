# Grafana configuration snapshots

Reviewed on 2026-10-19 against the authenticated Grafana API. These files contain
no API token and do not automatically provision or overwrite live configuration.

- `grafana-alert-rules.json`: ten existing Grafana-managed rules in provisioning
  HTTP API format. The Proxmox temperature rule retains its 70°C threshold and
  five-minute pending period, with a verified five-minute recovery hold added.
- `grafana-notification-policy.json`: Twilio SMS routing, grouped by folder and
  alert name, 30-second group wait, five-minute group interval, four-hour repeat.
- `kuma-monitors.json`: credential-free inventory of 11 monitors, notification
  metadata and selected general settings. See `../docs/kuma-review.md` for
  findings. This is a review inventory, not an importable Kuma backup.

These are configuration snapshots, not full application backups. Restoring through
the Grafana API requires the referenced folder, data source and contact point to
exist with matching identifiers. Notification credentials, dashboards, accounts,
Kuma settings and history are not included. The existing SMS webhook contact point
and notification delivery have been reviewed separately; handset delivery has not
been verified.

Refresh snapshots after configuration changes. Do not send the exported list to
one API endpoint: each existing rule is restored with a PUT to
`/api/v1/provisioning/alert-rules/<uid>`, or created individually when absent.
Use the notification policy API separately. Review configuration before applying.

The installed Grafana 12.3.6 API uses `keep_firing_for` for recovery duration.
The camel-case `keepFiringFor` field shown in newer documentation is ignored by
this installation; changes must be checked by reading the saved rule back.

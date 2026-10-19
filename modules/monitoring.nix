{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";

    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "hwmon"
        "loadavg"
        "meminfo"
        "netdev"
        "os"
        "systemd"
        "time"
      ];
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          { targets = [ "127.0.0.1:9100" ]; }
        ];
        scrape_interval = "15s";
      }
      {
        job_name = "proxmox-node";
        static_configs = [
          { targets = [ "192.168.4.175:9100" ]; labels = { instance = "prometheox"; }; }
        ];
        scrape_interval = "15s";
      }
      {
        job_name = "proxmox-pve";
        static_configs = [
          { targets = [ "192.168.4.175:9221" ]; }
        ];
        scrape_interval = "30s";
        metrics_path = "/pve";
        params = { target = [ "localhost" ]; };
      }
    ];
  };

  # Uptime Kuma — service availability monitoring
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3002";
      HOST = "0.0.0.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3002 ];

  # Preserve UI-managed rules, contact points, monitors and notification settings.
  # Encrypt to the existing sops age recipient before writing to shared storage.
  systemd.services.monitoring-backup = {
    description = "Encrypted Grafana and Uptime Kuma backup";
    requires = [ "mnt-nas.mount" ];
    after = [ "mnt-nas.mount" ];
    path = [ pkgs.age ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      UMask = "0077";
      PrivateTmp = true;
      ProtectHome = true;
      NoNewPrivileges = true;
      TimeoutStartSec = "15min";
    };
    script = ''
      exec ${pkgs.python3}/bin/python3 ${../scripts/monitoring-backup.py} \
        --grafana-dir ${config.services.grafana.dataDir} \
        --grafana-db ${config.services.grafana.settings.database.path} \
        --grafana-settings ${pkgs.writeText "grafana-backup-settings.json" (builtins.toJSON config.services.grafana.settings)} \
        --kuma-dir /var/lib/uptime-kuma \
        --destination /mnt/nas/Backups/monitoring \
        --recipient age1knxjl6gst5anu4k50kquek5fkx4mge22qg7kts5up82s4a6hsf2qt3fjfs
    '';
  };

  systemd.timers.monitoring-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:15:00";
      RandomizedDelaySec = "10min";
      Persistent = true;
    };
  };

  # Grafana-Twilio bridge — converts Grafana webhook JSON to Twilio SMS
  systemd.services.grafana-twilio-bridge = {
    description = "Grafana to Twilio SMS bridge";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
      LoadCredential = [
        "twilio-sid:/run/secrets/twilio-account-sid"
        "twilio-token:/run/secrets/twilio-auth-token"
        "twilio-from:/run/secrets/twilio-from-number"
        "twilio-to:/run/secrets/twilio-to-number"
      ];
    };
    script = ''
      export TWILIO_SID=$(cat $CREDENTIALS_DIRECTORY/twilio-sid)
      export TWILIO_TOKEN=$(cat $CREDENTIALS_DIRECTORY/twilio-token)
      export TWILIO_FROM=$(cat $CREDENTIALS_DIRECTORY/twilio-from)
      export TWILIO_TO=$(cat $CREDENTIALS_DIRECTORY/twilio-to)
      exec ${pkgs.nodejs}/bin/node ${../scripts/grafana-twilio-bridge.js}
    '';
  };

  services.grafana = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "dash.ivanvanrooyen.com";
        root_url = "https://dash.ivanvanrooyen.com";
      };
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };
}

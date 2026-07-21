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
    ];
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

{ config, pkgs, ... }:

{
  # PostgreSQL database
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "firefly-iii" ];
    ensureUsers = [
      {
        name = "firefly-iii";
        ensureDBOwnership = true;
      }
    ];
  };

  # Firefly III
  services.firefly-iii = {
    enable = true;
    enableNginx = true;
    virtualHost = "firefly-iii";
    settings = {
      APP_ENV = "production";
      APP_KEY_FILE = "/run/secrets/firefly-iii-app-key";
      SITE_OWNER = "ivan@ivanvanrooyen.com";
      DB_CONNECTION = "pgsql";
      DB_DATABASE = "firefly-iii";
      DB_USERNAME = "firefly-iii";
      APP_URL = "http://localhost:8084";
    };
  };

  # Firefly III Data Importer
  services.firefly-iii-data-importer = {
    enable = true;
    enableNginx = true;
    virtualHost = "firefly-iii-importer";
    settings = {
      FIREFLY_III_URL = "http://localhost:8084";
    };
  };

  # Nginx: custom listen ports (avoids conflict, keeps services on distinct ports)
  services.nginx.virtualHosts."firefly-iii" = {
    listen = [{ addr = "0.0.0.0"; port = 8084; }];
  };
  services.nginx.virtualHosts."firefly-iii-importer" = {
    listen = [{ addr = "0.0.0.0"; port = 8085; }];
  };

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [ 8084 8085 ];
}

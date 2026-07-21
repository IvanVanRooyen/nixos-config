{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  networking.firewall.allowedTCPPorts = [ 32400 13378 ];
  networking.firewall.allowedUDPPorts = [ 4242 ];

  # Cloudflare Tunnel
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file /etc/cloudflared/tunnel-token";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "cloudflared";
      Group = "cloudflared";
      NoNewPrivileges = true;
    };
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  users.groups.cloudflared = {};

  systemd.tmpfiles.rules = [
    "d /etc/cloudflared 0755 cloudflared cloudflared -"
    "z /etc/cloudflared/tunnel-token 0600 cloudflared cloudflared -"
  ];
}

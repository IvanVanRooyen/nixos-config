{ config, pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Trust all traffic from the Tailscale interface — Tailscale already
  # authenticates at the network level, so any service on this machine
  # becomes accessible to devices on the tailnet.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}

{ config, pkgs, ... }:

{
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets."nas-credentials" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."cloudflare-tunnel-token" = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  sops.secrets."firefly-iii-app-key" = {
    owner = "root";
    group = "root";
    mode = "0444";
  };
}

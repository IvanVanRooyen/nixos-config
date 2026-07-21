{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--keep-last 10";
  };

  nix.settings.auto-optimise-store = true;

  virtualisation.docker = {
    enable = true;
  };
}

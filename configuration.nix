{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/desktop.nix
    ./modules/hardware.nix
    ./modules/media.nix
    ./modules/monitoring.nix
    ./modules/networking.nix
    ./modules/nix.nix
    ./modules/packages.nix
    ./modules/storage.nix
    ./modules/sunshine.nix
  ];

  # System identity
  networking.hostName = "nixos";
  system.stateVersion = "25.11";

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Locale
  time.timeZone = "Australia/Brisbane";
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Keyboard
  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # Primary user
  users.users.ivanvr = {
    isNormalUser = true;
    description = "Ivan";
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
  };

  nixpkgs.config.allowUnfree = true;
}

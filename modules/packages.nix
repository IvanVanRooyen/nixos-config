{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wget
    kitty
    foot
    waybar
    wofi
    rofi
    mako
    grim
    slurp
    wl-clipboard
    cliphist
    xfce.thunar
    firefox
    git
    cloudflared
    hyprpaper
    nwg-look
    adw-gtk3
    neofetch
    home-manager
    cbonsai
    claude-code
    jq
  ];
}

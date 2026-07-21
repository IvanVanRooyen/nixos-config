{ config, pkgs, ... }:

{
  # Plex
  services.plex = {
    enable = true;
    openFirewall = true;
    accelerationDevices = [ "*" ];
  };

  # Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "users" "video" "render" ];

  # Audiobookshelf
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    openFirewall = true;
  };

  # Immich (photos)
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
  };
  users.users.immich.extraGroups = [ "users" ];

  # Overseerr (requests)
  services.overseerr = {
    enable = true;
    port = 5055;
    openFirewall = true;
  };

  # Radarr (movies)
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.radarr.extraGroups = [ "users" ];

  # Sonarr (TV shows)
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.sonarr.extraGroups = [ "users" ];

  # Prowlarr (indexer)
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # qBittorrent
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8080;
  };
  users.users.qbittorrent.extraGroups = [ "users" ];
}

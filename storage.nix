{config, pkgs, ... }:

  # ===========================================================
  # STORAGE CONFIGURATION
  # Manages the SMB/CIFS mount from the TrueNAS server and
  # the system packages required to support it.
  # ===========================================================
                                                                                                       
{               
  # cifs-utils provides the kernel-level utilities needed to mount                                   
  # CIFS (SMB) network shares. Without this package, the NAS mount
  # will fail at boot and on reconnect attempts.                                                     
  environment.systemPackages = with pkgs; [ 
    cifs-utils                                                                                       
  ];                                        
                                                                                                       
  # ===========================================================
  # NAS MOUNT — TrueNAS VM at 192.168.4.60                                                           
  # Share: SMBNASVault → mounted at /mnt/nas
  #                                                                                                  
  # This share holds all media libraries used by Plex, Jellyfin,
  # Audiobookshelf, Immich, Radarr, Sonarr, and qBittorrent.
  #                                                                                                  
  # Credentials are stored outside the Nix store at:
  # /etc/nixos/smb/nas-credentials                                                                                                                                               
  # Never put credentials directly in this config file.
  # ===========================================================                                      
  systemd.mounts = [{                                                                                  
    what = "//192.168.4.60/SMBNASVault";                                                               
    where = "/mnt/nas";
    type = "cifs";                                                                                     
    options = "credentials=/etc/nixos/smb/nas-credentials,uid=1000,gid=100,iocharset=utf8,_netdev,x-systemd.device-timeout=10s,echo_interval=60,file_mode=0775,dir_mode=0775,noperm";               
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];                                                               
    mountConfig = {                                                                                    
      TimeoutSec = "30s";
    };                                                                                                 
  }];             

  systemd.automounts = [{
    where = "/mnt/nas";
    wantedBy = [ "multi-user.target" ];
    automountConfig = {                                                                                
      TimeoutIdleSec = "600";
    };                                                                                                 
  }];                                                                                                
}   

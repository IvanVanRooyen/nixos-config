{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  # NAS mount — TrueNAS VM at 192.168.4.60
  # Share: SMBNASVault -> /mnt/nas
  # Credentials stored at /etc/nixos/smb/nas-credentials
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

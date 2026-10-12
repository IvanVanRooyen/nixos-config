{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.ivanvr.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtp8R076Kuwva4vztDxm45TBPfkBfsWptM/1ILogODJ ivanvanrooyen1666@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWVS7xkR8CXKt429Ce544KHtvtxr4N4cWEszstZ96UD ivanvr@iphone"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESPzIiYdlMyarEuccKN8V54AFQ2Nn74x5VqP/pBT3ZT ivanvr@windows-laptop"
  ];
}

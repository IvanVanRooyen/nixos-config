{ config, pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false;
    openFirewall = true;
  };

  # Expose NVIDIA encode/CUDA libs for NVENC
  systemd.user.services.sunshine.environment = {
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };

  # Ensure sunshine process has input/uinput group access
  systemd.user.services.sunshine.serviceConfig = {
    SupplementaryGroups = [ "input" "uinput" ];
  };
}

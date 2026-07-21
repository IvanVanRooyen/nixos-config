# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./storage.nix # Nas Mounting
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.firewall.allowedTCPPorts = [ 32400 13378 ];
  networking.firewall.allowedUDPPorts = [ 4242]; # For LAN Mouse

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  # Select internationalisation properties.
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ivanvr = {
    isNormalUser = true;
    description = "Ivan";
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
    packages = with pkgs; [];
  };

  users.users.immich.extraGroups = [ "users" ];
  users.users.radarr.extraGroups = [ "users" ];
  users.users.sonarr.extraGroups = [ "users" ];
  users.users.qbittorrent.extraGroups = [ "users" ];
  users.users.jellyfin.extraGroups = [ "users" "video" "render" ];
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  wget
  kitty
  waybar 
  wofi # app launcher 
  mako 
  grim 
  slurp 
  wl-clipboard 
  xfce.thunar 
  firefox 
  git 
  foot # another terminal 
  cloudflared
  hyprpaper # Wallpaper
  nwg-look # theme switching
  adw-gtk3 # a theme
  neofetch # cli art
  home-manager # manages user configs/settings?
  rofi # another app launcher 
  cbonsai # ascii animation 
  claude-code #AI 
  jq # JSON processor for Claude Code hooks (protocol injection at start of session)
  cliphist # clipboard memory 
  grim #screenshot tool 
  slurp # screenshot area tool 
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  
  # AUDIOBOOKSHELF #  
  services.audiobookshelf = {
	enable = true; 
	host = "0.0.0.0";
	port = 13378; 
	openFirewall = true; 
  };  
 
  # IMMICH # PHOTOS 
  services.immich = {
	enable = true; 
	port = 2283; 
	openFirewall = true;

  };

  # JELLYFIN # 
  services.jellyfin = {
	enable = true; 
	openFirewall = true; 
  };

  # OVERSEERR # REQUESTS
  services.overseerr = {
	enable = true;
	port = 5055; 
	openFirewall = true; 
  };

  # RADARR # MOVIES
  services.radarr = {
	enable = true; 
	openFirewall = true;   
  };

  # SONARR # TV SHOWS 
  services.sonarr = {
	enable = true; 
	openFirewall = true; 
  };

  # PROWLARR # INDEXER 
  services.prowlarr = {
	enable = true; 
	openFirewall = true; 
  }; 

  # QBITORRENT # 
  services.qbittorrent = {
	enable = true; 
	openFirewall = true; 
	webuiPort = 8080; 
  };

  # TUMBLER # 
  # Just renders thumbnails for thunar I think 
  services.tumbler.enable = true; 

  # SUNSHINE # Remot Desktop Streaming 
  services.sunshine = {                                                                                
    enable = true;                                                                                     
    autoStart = true;
    capSysAdmin = false;                                                                                
    openFirewall = true;
  };   
  hardware.uinput.enable = true;   
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input", SYMLINK+="uinput"                                    
  '';
  # Expose NVIDIA encode/CUDA libs to the Sunshine user service for NVENC
  systemd.user.services.sunshine.environment = {
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
  # Fix: ensure sunshine process has input/uinput group access
  systemd.user.services.sunshine.serviceConfig = {                                                   
    SupplementaryGroups = [ "input" "uinput" ];
  };   
 
  # PROMETHEUS # MONITORING & METRICS
  services.prometheus = {
	enable = true; 
	port = 9090; 
	retentionTime = "30d";

	exporters.node = {
	  enable = true; 
	  port = 9100; 
	  enabledCollectors = [
		"cpu"
		"diskstats" 
		"filesystem"
		"hwmon" 
		"loadavg" 
		"meminfo"
		"netdev" 
		"os" 
		"systemd" 
		"time" 
	  ];
	};
	
	scrapeConfigs = [
	  {
	    job_name = "node";
	    static_configs = [
		{ targets = ["127.0.0.1:9100"]; }
	    ];
	    scrape_interval = "15s";
	  }
	];
  };

  # GRAFANA # 
  services.grafana = { 
	enable = true; 
	openFirewall = true; 
	settings = {
	  server = { 
		http_addr = "0.0.0.0";
		http_port = 3000; 
		domain = "dash.ivanvanrooyen.com";
		root_url = "https://dash.ivanvanrooyen.com";
	  };
	};
	provision = {
	  datasources.settings.datasources = [
		{
		  name = "Prometheus";
		  type = "prometheus";
		  url = "http://127.0.0.1:9090";
		  isDefault = true; 
		}
	  ];
	};
  };


  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  ######## MY STUFF ######


  # fonts 
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
  ];

  hardware.graphics.enable = true; 
  hardware.graphics.enable32Bit = true; 
  # load the nvidia driver 
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
	modesetting.enable = true; 
	open = false; 
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];  

  ## Garbage cleanup mechanism (deletes old nix generations) 
  nix.gc = {
	automatic = true; 
	dates = "weekly";
	options = "--keep-last 10";
  };

  ## Deduplicate identical files in the Nix store to save disk space
  nix.settings.auto-optimise-store = true;

  programs.hyprland = {
	enable = true; 
	xwayland.enable = true; 
  };

  services.greetd = {
	enable = true; 
	settings.default_session = {
		command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
		user = "greeter"; 
	};
  };

  environment.sessionVariables = {
	NIXOS_OZONE_WL = "1";
	WLR_NO_HARDWARE_CURSORS = "1";
  };

  xdg.portal = {
	enable = true; 
	extraPortals = [ 
		pkgs.xdg-desktop-portal-hyprland 
		pkgs.xdg-desktop-portal-gtk
	];
  };

  services.plex = {
	enable = true; 
	openFirewall = true; 
	accelerationDevices = ["*"];
  };

  virtualisation.docker = {
	enable = true; 
  };

  ######################
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file /etc/cloudflared/tunnel-token";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "cloudflared";
      Group = "cloudflared";
      NoNewPrivileges = true;
    };
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  users.groups.cloudflared = {};

  systemd.tmpfiles.rules = [
  "d /etc/cloudflared 0755 cloudflared cloudflared -"
  "z /etc/cloudflared/tunnel-token 0600 cloudflared cloudflared -"
  ];

}

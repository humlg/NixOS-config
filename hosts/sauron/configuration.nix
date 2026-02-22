# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
 
{ config, lib, pkgs, inputs, ... }:
 
{
  imports =
    [
      ./hardware-configuration.nix
      ./file-system.nix
      ../../modules/system/locale.nix
      ../../modules/system/nvidia.nix
      ../../modules/system/sddm.nix
      ../../modules/services/bluetooth.nix
      #./modules/desktop/hyprland.nix
    ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
 
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [ "nct6775" ];
 
  networking.hostName = "sauron"; # Define your hostname.
 
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
 
  # Set your time zone.
  time.timeZone = "Europe/Prague";
 
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
 
 console = {
    font = "Lat2-Terminus16";
    keyMap = "cz";
 };
 
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
 
  security.polkit.enable = true;
 
  systemd.user.services.polkit-agent = {
    description = "Polkit Authentication Agent";
    wantedBy = [ "default.target" ];
 
      serviceConfig = {
        ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
        Restart = "on-failure";
      };
    };

  environment.variables = {
  NIXPKGS_ALLOW_UNFREE = 1;
  };
  
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";

    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = "48";

    #KITTY_DISABLE_WAYLAND = "1";
  };

 
  # Configure keymap in X11
   services.xserver.xkb.layout = "cz";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";
 
  # Enable CUPS to print documents.
   services.printing.enable = true;
 
   services.colord.enable = true;

   #services.lm_sensors.enable = true;

  # Enable sound.
   services.pipewire = {
     enable = true;
     pulse.enable = true;
   };
 
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable touchpad support (enabled default in most desktopManager).
   services.libinput.enable = true;
 
  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.david = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     shell = pkgs.zsh;
     packages = with pkgs; [
       tree
     ];
   };
   users.users.root.shell = pkgs.zsh;

   home-manager = {
    extraSpecialArgs = { inherit inputs;};
    users = {
      "david" = import ./home.nix;
    };
   };
 
   programs.firefox.enable = true;
   programs.thunar.enable = true;
   programs.zsh = {
  enable = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  ohMyZsh = {
    enable = true;
    plugins = ["git"];
    theme = "agnoster";
  };
  interactiveShellInit = ''
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch
    fi
    '';
   };
   programs.kdeconnect.enable = true;
   programs.coolercontrol.enable = true;
 
  # Enable non-free nix packages
  nixpkgs.config.allowUnfree = true;
 
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
   environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    btop
    kitty
    gtk3
    xterm
    alacritty
    rofi
    wofi
    waybar
    git
    unzip
    pywal16
    waypaper
    chromium
    swww
    curl
    wget
    spice-vdagent
    volantes-cursors
    fastfetch
    discord
    vscode
    lxqt.lxqt-policykit
    steam
    kdePackages.kate
    mpv
    ffmpeg
    pywalfox-native
    sddm-sugar-dark
    quickshell
    pavucontrol
    kdePackages.kdeconnect-kde
    cliphist
    wl-clipboard
    hyprlock
    hypridle
    lm_sensors
    stress
    cava
    openrgb
    hyprshot
    swaynotificationcenter
    obsidian
    usbutils
    blueman
    gamescope
    udiskie
    librewolf
    tree
    spotify
    feh
    darktable
    lazygit
  ];
 
 
   fonts.packages = with pkgs; [
   nerd-fonts.jetbrains-mono
   ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
 
  # List services that you want to enable:
 
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
 
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
 
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
 
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
 
}

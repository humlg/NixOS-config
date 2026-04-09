{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/nvidia.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-system.nix
    ../../modules/programs/zsh.nix
    ../../modules/services/bluetooth.nix
    ../../modules/bundles/photography.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/bundles/gaming.nix
  ];

  networking.hostName = "sauron";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" ];

  # HiDPI: larger font for TTY console and boot menu
  boot.loader.systemd-boot.consoleMode = "max";
  #console.packages = [ pkgs.terminus_font ];
  #console.font = "ter-132b";

  services.colord.enable = true;

  programs.kdeconnect.enable = true;
  programs.coolercontrol.enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users = {
      "david" = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    btop
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
    spice-vdagent
    discord
    vscode
    lxqt.lxqt-policykit
    kdePackages.kate
    mpv
    ffmpeg
    pywalfox-native
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
    librewolf
    tree
    spotify
    feh
    lazygit
  ];

  system.stateVersion = "25.11";
}

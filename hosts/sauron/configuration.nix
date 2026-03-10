{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/nvidia.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-nixos.nix
    ../../modules/programs/shell.nix
    ../../modules/services/bluetooth.nix
    ../../modules/bundles/graphical.nix
  ];

  networking.hostName = "sauron";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" ];

  services.colord.enable = true;

  programs.kdeconnect.enable = true;
  programs.coolercontrol.enable = true;

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
    fastfetch
    discord
    vscode
    lxqt.lxqt-policykit
    steam
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
    gamescope
    librewolf
    tree
    spotify
    feh
    lazygit
  ];

  system.stateVersion = "25.11";
}

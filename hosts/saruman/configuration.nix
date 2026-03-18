{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-nixos.nix
    ../../modules/programs/shell.nix
    ../../modules/services/bluetooth.nix
    ../../modules/bundles/graphical.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/programs/mullvad.nix
  ];

  networking.hostName = "saruman";

  # LUKS encryption (swap partition)
  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  services.colord.enable = true;

  # Battery charge limit for Lenovo IdeaPad 14ASP9
  # Conservation mode caps charge at ~60% via ideapad_laptop kernel module
  boot.kernelModules = [ "ideapad_laptop" ];
  systemd.services.ideapad-conservation-mode = {
    description = "Enable Lenovo IdeaPad conservation mode";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/platform/devices/VPC*/conservation_mode'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/bus/platform/devices/VPC*/conservation_mode'";
    };
  };

  programs.kdeconnect.enable = true;
  bundles.wine.enable = true;

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
    curl
    htop
    btop
    gtk3
    rofi
    waybar
    git
    unzip
    pywal16
    waypaper
    chromium
    swww
    fastfetch
    discord
    vscode
    steam
    kdePackages.kate
    mpv
    ffmpeg
    pywalfox-native
    pavucontrol
    kdePackages.kdeconnect-kde
    cliphist
    wl-clipboard
    hyprlock
    hypridle
    hyprshot
    swaynotificationcenter
    obsidian
    blueman
    librewolf
    tree
    spotify
    lazygit
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";
}

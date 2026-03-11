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
  ];

  networking.hostName = "saruman";

  # LUKS encryption (swap partition)
  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  services.colord.enable = true;

  # Battery charge limit for Lenovo IdeaPad 14ASP9
  services.tlp = {
    enable = true;
    settings = {
      # Conservation mode caps charge at ~80% (IdeaPad-specific)
      NATACPI_ENABLE = 1;
      CONSERVATION_MODE = 1;
    };
  };

  programs.kdeconnect.enable = true;

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

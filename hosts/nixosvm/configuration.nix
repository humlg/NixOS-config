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
  ];

  networking.hostName = "nixosvm";

  # Virtual Machine agent
  services.spice-vdagentd.enable = true;

  environment.variables = {
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = 36;
  };

  home-manager = {
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
    volantes-cursors
    discord
    vscode
    lxqt.lxqt-policykit
    steam
    kdePackages.kate
    mpv
    ffmpeg
    pywalfox-native
    quickshell
    tmux
    transmission_4-gtk
  ];

  system.stateVersion = "25.11";
}

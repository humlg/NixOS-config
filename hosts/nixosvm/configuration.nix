{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/system/common.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/sddm.nix
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/programs/zsh.nix
    ../../modules/nixos/services/bluetooth.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  networking.hostName = "nixosvm";

  custom.bluetooth.enable = true;
  custom.tailscale.enable = true;

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
    wofi
    chromium
    spice-vdagent
    volantes-cursors
    discord
    vscode
    steam
    kdePackages.kate
    quickshell
    tmux
    transmission_4-gtk
  ];

  system.stateVersion = "25.11";
}

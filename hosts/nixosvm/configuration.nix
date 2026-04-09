{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-system.nix
    ../../modules/programs/zsh.nix
    ../../modules/services/bluetooth.nix
  ];

  networking.hostName = "nixosvm";

  custom.bluetooth.enable = true;

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

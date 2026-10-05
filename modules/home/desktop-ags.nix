{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  # Disabled under Noctalia (Phase C of the migration) rather than deleted —
  # see maintenance.md item 19.
  config = lib.mkIf (cfg.enable && !cfg.useNoctalia) {
    programs.ags = {
      enable = true;
      configDir = ./ags-config;
      extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
        astal4
        battery
        hyprland
        tray
        wireplumber
      ];
    };
  };
}

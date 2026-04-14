{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  config = lib.mkIf cfg.enable {
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

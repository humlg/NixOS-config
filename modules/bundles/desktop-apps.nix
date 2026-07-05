{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.desktop-apps;
in
{
  options.bundles.desktop-apps = {
    enable = lib.mkEnableOption "Common desktop applications";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      discord
      vscode
      kdePackages.kate
      chromium
      spotify
      megasync
      transmission_4-gtk
    ];
  };
}

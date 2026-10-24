{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.yg-work;
in
{
  imports = [

  ];
  options.bundles.yg-work = {
    enable = lib.mkEnableOption "Bundle of tools used for work in Yellow Grid";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mqttx
      slack
      teams-for-linux
      libreoffice-qt
      todoist-electron
      mqttui
      dm-sans  # Yellow Grid brand font, used in work LibreOffice docs
      glabels-qt  # label design for the Godex G530 printer
    ];
  };
}

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
      teams
      
    ];
  };
}

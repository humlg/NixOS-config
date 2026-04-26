{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.photography;
in
{
  options.bundles.photography = {
    enable = lib.mkEnableOption "Photography and graphics applications bundle";
  };

  config = lib.mkIf cfg.enable {
    # Graphics and photography applications bundle
    environment.systemPackages = with pkgs; [
      gimp          # GNU Image Manipulation Program
      inkscape      # Vector graphics editor
      darktable     # Photography workflow and RAW developer
      #rawtherapee
      gphoto2
      davinci-resolve
    ];
  };
}

{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.photography;
in
{
  options.bundles.photography = {
    enable = lib.mkEnableOption "Photography and graphics applications bundle";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gimp
      inkscape
      darktable
      #rawtherapee  # disabled, see docs/maintenance.md #2
      gphoto2
    ];
  };
}

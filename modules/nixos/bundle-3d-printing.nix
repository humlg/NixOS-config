{ config, lib, pkgs, ... }:

let
  cfg = config.bundles."3d-printing";
in
{
  options.bundles."3d-printing" = {
    enable = lib.mkEnableOption "3D printing and CAD applications bundle";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prusa-slicer
      #bambu-studio  # disabled, no reason recorded — docs/maintenance.md #17
      printrun
    ];
  };
}

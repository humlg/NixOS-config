{ config, lib, pkgs, ... }:

let
  cfg = config.bundles."3d-printing";
in
{
  options.bundles."3d-printing" = {
    enable = lib.mkEnableOption "3D printing and CAD applications bundle";
  };

  config = lib.mkIf cfg.enable {
    # 3D printing and CAD applications bundle
    environment.systemPackages = with pkgs; [
      prusa-slicer   # 3D print slicing
      freecad-wayland # Parametric CAD modeling (Wayland-native)
      bambu-studio
    ];
  };
}

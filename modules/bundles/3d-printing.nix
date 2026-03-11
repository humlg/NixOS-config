{ config, pkgs, ... }:

{
  # 3D printing and CAD applications bundle
  environment.systemPackages = with pkgs; [
    prusa-slicer   # 3D print slicing
    freecad-wayland # Parametric CAD modeling (Wayland-native)
  ];
}

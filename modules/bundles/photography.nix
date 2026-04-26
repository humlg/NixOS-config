{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.photography;

  # DaVinci Resolve uses bundled Qt5. When WAYLAND_DISPLAY is set (Hyprland),
  # Qt defaults to the Wayland platform which DR doesn't support — force xcb.
  davinci-resolve-xcb = pkgs.symlinkJoin {
    name = "davinci-resolve";
    paths = [ pkgs.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/davinci-resolve \
        --set QT_QPA_PLATFORM xcb
    '';
  };
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
      davinci-resolve-xcb
    ];
  };
}

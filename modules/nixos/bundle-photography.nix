{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.photography;

  # Forces XCB — DR's bundled Qt5 can't do Wayland (docs/maintenance.md #12).
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
    environment.systemPackages = with pkgs; [
      gimp
      inkscape
      darktable
      #rawtherapee  # disabled, see docs/maintenance.md #2
      gphoto2
      davinci-resolve-xcb
      audacity
    ];
  };
}

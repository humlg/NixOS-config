{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
  ];

  bundles.general.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    monitors = "monitor = ,2880x1800@60,auto,2";

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";
  };
}

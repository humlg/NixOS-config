{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/program-fastfetch.nix
    ../../modules/home/program-thunar.nix
    ../../modules/home/desktop-dark-theme.nix
    ../../modules/home/bundle-general.nix
    ../../modules/home/desktop-hyprland-desktop.nix
  ];

  bundles.general.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useLuaConfig = true;

    monitors    = "monitor = ,2880x1800@60,auto,2";
    monitorsLua = ''hl.monitor({ output = "", mode = "2880x1800@60", position = "auto", scale = 2 })'';


    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";
  };
}

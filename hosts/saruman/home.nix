{ config, pkgs, ... }:

{
  imports = [
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
    ../../modules/bundles/yg-work.nix
  ];

  nixpkgs.config.allowUnfree = true;

  bundles.general.enable = true;
  bundles.yg-work.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = DP-2,preferred@100,1440x0,1
      monitor = ,preferred,auto,1,mirror,eDP-1
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";
  };

  home.username = "david";
  home.homeDirectory = "/home/david";

  home.stateVersion = "25.11";

  home.packages = [];

  home.file = {};

  home.sessionVariables = {
    EDITOR = "vim";
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = 24;
  };

  home.pointerCursor = {
    name = "volantes_cursors";
    size = 24;
    package = pkgs.volantes-cursors;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk.cursorTheme = {
    name = "volantes_cursors";
    size = 24;
    package = pkgs.volantes-cursors;
  };

  xresources.properties = {
    "Xft.dpi" = 96;
  };

  programs.zsh.enable = true;
  programs.home-manager.enable = true;
}

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

    monitors = "monitor = ,2880x1800@120,auto,2";

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

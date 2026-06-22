{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
    ../../modules/programs/cava.nix
    ../../modules/services/megacmd.nix
    ../../modules/bundles/desktop-apps.nix
  ];

  bundles.general.enable = true;
  bundles.desktop-apps.enable = true;

  services.megacmd = {
    enable = true;
    syncs = {
      "/home/david/Documents" = "/Documents";
      "/home/david/Pictures" = "/Pictures";
    };
  };

  desktop.hyprland-desktop = {
    enable = true;

    # Machine-specific monitor layout (sauron — desktop with external display)
    monitors = ''
      monitor = DP-2, 2560x1440@165.08, 1920x0, 1
      monitor = HDMI-A-1, 1920x1080@75, 0x0, 1
      monitor = , preferred, auto, 1
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";

    # FreeSync/VRR — enabled only on this AMD host; fullscreen-only avoids
    # compositor tearing in normal use while still benefiting games.
    extraConfig = ''
      misc {
        vrr = 2
      }
    '';
  };

  home.sessionVariables = {
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
}

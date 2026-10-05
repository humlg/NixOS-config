{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/program-fastfetch.nix
    ../../modules/home/program-thunar.nix
    ../../modules/home/desktop-dark-theme.nix
    ../../modules/home/bundle-general.nix
    ../../modules/home/desktop-hyprland-desktop.nix
    ../../modules/home/program-ssh-keys.nix
    ../../modules/home/program-cava.nix
    ../../modules/home/program-newsboat.nix
    ../../modules/home/program-transmission.nix
    ../../modules/home/program-jellyfin-media-player.nix
    ../../modules/home/bundle-desktop-apps.nix
  ];

  bundles.general.enable = true;
  bundles.desktop-apps.enable = true;
  custom.transmission-vpn.enable = true;
  programs.jellyfin-media-player.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useLuaConfig = true;

    useNoctalia = true;  # full replacement here (see custom.noctalia.enable) — docs/maintenance.md #19

    monitors = ''
      monitor = DP-2, 2560x1440@165.08, 1920x0, 1
      monitor = HDMI-A-1, 1920x1080@75, 0x0, 1
      monitor = , preferred, auto, 1
    '';
    monitorsLua = ''
      hl.monitor({ output = "DP-2",     mode = "2560x1440@165.08", position = "1920x0", scale = 1 })
      hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75",     position = "0x0",    scale = 1 })
      hl.monitor({ output = "",         mode = "preferred",          position = "auto",   scale = 1 })
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";

    # FreeSync/VRR, fullscreen-only — avoids compositor tearing while still benefiting games.
    extraConfig = ''
      misc {
        vrr = 2
      }
    '';
    extraLuaConfig = ''
      hl.config({ misc = { vrr = 2 } })
    '';

    # Wiggle the mouse → the cursor briefly grows (KDE Shake Cursor style).
    dynamicCursors.enable = true;

    # Merges with the module's default list (docs/architecture.md). newsboat's key is
    # null — mainMod+X/SHIFT+X already toggle special:dashboard, a second bind would double it.
    silentApps = [
      {
        name         = "rssReader";
        command      = "io.gitlab.news_flash.NewsFlash";
        class        = "^io\\.gitlab\\.news_flash\\.NewsFlash$";
        matchInitial = false;
        workspace    = "rss";
        key          = "U";
        delay        = 5;
      }
      {
        name         = "newsboatReader";
        command      = "kitty --class newsboat -e newsboat";
        class        = "^newsboat$";
        matchInitial = false;
        workspace    = "dashboard";
        key          = null;
        delay        = 6;
      }
    ];
  };

  home.sessionVariables = {
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = 24;
  };

  home.pointerCursor = {
    enable = true;
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

{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
    ../../modules/bundles/yg-work.nix
    ../../modules/programs/webapps.nix
    ../../modules/services/megacmd.nix
    ../../modules/bundles/desktop-apps.nix
    ../../modules/programs/librewolf.nix
  ];

  bundles.general.enable = true;
  bundles.desktop-apps.enable = true;
  programs.librewolf-custom.enable = true;
  bundles.yg-work.enable = true;

  services.megacmd = {
    enable = true;
    syncs = {
      "/home/david/Documents" = "/documents";
      "/home/david/Pictures/Screenshots" = "/Pictures/Screenshots";
      "/home/david/Pictures/Film_Archive" = "/Pictures/Film_Archive";
      "/home/david/Pictures/Digital_archive" = "/Pictures/Digital_Archive";
      "/home/david/YellowGrid" = "/YellowGrid";

      "/home/david/Pictures/Wallpapers" = "/Pictures/Wallpapers";
    };
  };

  desktop.hyprland-desktop = {
    enable = true;

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = desc:Iiyama North America PL2797H 12497503A1590,1920x1080@100,1440x0,1
      monitor = ,preferred,auto,1,mirror,eDP-1
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";

    extraConfig = ''
      xwayland {
          force_zero_g = true
      }
    '';
  };

  home.packages  = [
    pkgs.crosspipe
    pkgs.qemu
    pkgs.cameractrls-gtk4
    pkgs.remmina
  ];

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

  programs.webapps = {
    enable = true;
    apps = {
      Youtube-music = {
        url = "https://music.youtube.com";
        icon = "youtube-music";
        categories = [ "Audio" "Music" ];
      };
      Claude = {
        url = "https://claude.ai";
        categories = [ "Network" ];
      };
      Chatgpt = {
        url = "https://chat.openai.com";
      };
    };
  };

  programs.zsh.enable = true;
}

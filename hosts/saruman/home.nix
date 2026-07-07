{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
    ../../modules/programs/ssh-keys.nix
    ../../modules/bundles/yg-work.nix
    ../../modules/programs/webapps.nix
    ../../modules/bundles/desktop-apps.nix
  ];

  bundles.general.enable = true;
  bundles.desktop-apps.enable = true;
  bundles.yg-work.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useLuaConfig = true;

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = desc:Iiyama North America PL2797H 12497503A1590,1920x1080@100,1440x0,1
      monitor = ,preferred,auto,1
    '';
    monitorsLua = ''
      hl.monitor({ output = "eDP-1", mode = "2880x1800@120",  position = "0x0",    scale = 2, bitdepth = 10, cm = "wide" })
      hl.monitor({ output = "desc:Iiyama North America PL2797H 12497503A1590", mode = "1920x1080@100", position = "1440x0", scale = 1 })
      hl.monitor({ output = "",      mode = "preferred",       position = "auto",   scale = 1 })
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";

    extraConfig = ''
      xwayland {
          force_zero_scaling = false
      }
    '';
    extraLuaConfig = ''
      hl.config({ xwayland = { force_zero_scaling = false } })

      -- wl-mirror properly centers 16:10 content on 16:9 screens with black bars.
      -- Hyprland 0.55+ built-in mirror left-aligns the scaled content instead.
      hl.window_rule({ match = { class = "^wl-mirror$" }, decorate = false })

      hl.on("monitor.added", function(m)
        local is_iiyama = m.description ~= nil and string.find(m.description, "Iiyama", 1, true) ~= nil
        if m.output ~= "eDP-1" and not is_iiyama then
          hl.exec_cmd("sleep 1 && hyprctl dispatch exec '[monitor " .. m.output .. " fullscreen silent]' 'wl-mirror eDP-1'")
        end
      end)
      hl.on("monitor.removed", function(m)
        local is_iiyama = m.description ~= nil and string.find(m.description, "Iiyama", 1, true) ~= nil
        if m.output ~= "eDP-1" and not is_iiyama then
          hl.exec_cmd("pkill wl-mirror")
        end
      end)
    '';
  };

  home.packages  = [
    pkgs.crosspipe
    pkgs.qemu
    pkgs.cameractrls-gtk4
    pkgs.remmina
    pkgs.wl-mirror
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

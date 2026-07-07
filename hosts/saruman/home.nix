{ config, pkgs, ... }:

let
  # Toggle external display between mirror (wl-mirror, 16:10→16:9 with black bars)
  # and extend (normal Hyprland workspace) modes.  SUPER+M to toggle.
  toggleDisplayMode = pkgs.writeShellScriptBin "toggle-display-mode" ''
    ext=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name != "eDP-1") | .name' | head -1)
    if [ -z "$ext" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Display toggle" "No external monitor connected"
      exit 1
    fi
    if pgrep -x wl-mirror > /dev/null; then
      pkill wl-mirror
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Display" "Extend mode"
    else
      hyprctl dispatch focusmonitor "$ext"
      wl-mirror eDP-1 &
      sleep 0.5
      hyprctl dispatch fullscreen
      hyprctl dispatch focusmonitor eDP-1
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Display" "Mirror mode"
    fi
  '';
in
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

      -- wl-mirror window: strip decorations so it looks like a true mirror
      hl.window_rule({ match = { class = "^wl-mirror$" }, decorate = false })

      -- SUPER+M: toggle external display between mirror and extend.
      -- Mirror uses wl-mirror which preserves 16:10 aspect ratio on 16:9 screens
      -- (black bars on both sides). Extend is the normal Hyprland behaviour.
      hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("toggle-display-mode"))
    '';
  };

  home.packages  = [
    pkgs.crosspipe
    pkgs.qemu
    pkgs.cameractrls-gtk4
    pkgs.remmina
    pkgs.wl-mirror
    toggleDisplayMode
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

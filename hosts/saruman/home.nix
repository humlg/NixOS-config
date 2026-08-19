{ config, pkgs, ... }:

let
  # Toggle eDP-1 between native (2880x1800) and Full HD (1920x1080, 16:9)
  # for TV mirroring/casting. The Lua config parser rejects `hyprctl
  # keyword`, so use `hyprctl eval`. Bound to SUPER+A.
  resolutionToggle = pkgs.writeShellScriptBin "resolution-toggle" ''
    width=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name=="eDP-1") | .width')
    if [ "$width" = "1920" ]; then
      hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 2, bitdepth = 10, cm = "wide" })'
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Resolution" "Native (2880x1800)" || true
    else
      hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@120", position = "0x0", scale = 1 })'
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Resolution" "Full HD (1920x1080)" || true
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
    ../../modules/programs/transmission.nix
    ../../modules/bundles/desktop-apps.nix
  ];

  bundles.general.enable = true;
  bundles.desktop-apps.enable = true;
  bundles.yg-work.enable = true;
  custom.transmission-vpn.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useLuaConfig = true;

    # Noctalia desktop shell pilot (2026-08-19) — runs alongside AGS/swaync/
    # hyprlock/waypaper for now (all still enabled below), not replacing them
    # yet. See the Noctalia migration plan: bar/notifications/wallpaper/lock
    # get validated standalone (Phase B) before any keybind/autostart cutover
    # (Phase C), and hypridle's lock_cmd is deliberately left on hyprlock
    # until Phase D, gated separately given saruman's sleep-hang history.
    useNoctalia = true;

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = desc:Iiyama North America PL2797H 12497503A1590,1920x1080@100,1440x-258,1
      monitor = ,preferred,auto,1,mirror,eDP-1
    '';
    monitorsLua = ''
      hl.monitor({ output = "eDP-1", mode = "2880x1800@120",  position = "0x0",    scale = 2, bitdepth = 10, cm = "wide" })
      hl.monitor({ output = "desc:Iiyama North America PL2797H 12497503A1590", mode = "1920x1080@100", position = "1440x-258", scale = 1 })
      hl.monitor({ output = "",      mode = "preferred",       position = "auto",   scale = 1, mirror = "eDP-1" })
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";

    # Currently inert: hypridle (the only consumer of this option) is disabled
    # on saruman while useNoctalia = true (see modules/desktop/hypridle.nix
    # and maintenance.md item 19) — Noctalia's own idle service now owns
    # dim/lock/dpms/sleep instead, configured outside Nix. Left set so the
    # value is correct again the moment useNoctalia flips back off. Matches
    # the logind lid/power-key paths in configuration.nix — third attempt at
    # plain suspend (2026-08-19), see maintenance.md item 7 for why the first
    # two failed and what to revert to if this one does too.
    sleepCommand  = "systemctl suspend";

    extraConfig = ''
      xwayland {
          force_zero_scaling = false
      }
    '';
    extraLuaConfig = ''
      hl.config({ xwayland = { force_zero_scaling = false } })

      -- Workaround for upstream Hyprland bug: mirroring outputs with different
      -- aspect ratios leaves stale scene data flickering in the pillarbox
      -- margin instead of clearing it to black. A reload fixes it.
      -- https://github.com/hyprwm/Hyprland/discussions/11708
      hl.on("monitor.added", function(monitor)
        if monitor.name ~= "eDP-1" then
          hl.exec_cmd("sleep 1 && hyprctl reload")
        end
      end)

      -- Toggle eDP-1 native/Full HD resolution (for TV mirroring)
      hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("resolution-toggle"))
    '';
  };

  home.packages  = [
    pkgs.crosspipe
    pkgs.qemu
    pkgs.cameractrls-gtk4
    pkgs.remmina
    pkgs.kdePackages.k3b
    resolutionToggle
  ];

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

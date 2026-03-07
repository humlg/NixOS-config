{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;
in
{
  options.desktop.hyprland-desktop = {
    enable = lib.mkEnableOption "Hyprland desktop home-manager environment";

    monitors = lib.mkOption {
      type    = lib.types.lines;
      default = "monitor = ,preferred,auto,1";
      description = "Raw Hyprland monitor configuration lines (machine-specific).";
    };

    lockScreen = lib.mkOption {
      type    = lib.types.str;
      default = "hyprlock";
      description = "Command used to lock the screen.";
    };

    screenshotDir = lib.mkOption {
      type    = lib.types.str;
      default = "${home}/Pictures/Screenshots";
      description = "Directory where hyprshot saves screenshots.";
    };

    terminal = lib.mkOption {
      type    = lib.types.str;
      default = "kitty";
      description = "Default terminal emulator command.";
    };

    fileManager = lib.mkOption {
      type    = lib.types.str;
      default = "thunar";
      description = "Default file manager command.";
    };
  };

  config = lib.mkIf cfg.enable {

    # ── Packages ────────────────────────────────────────────────────────────
    home.packages = with pkgs; [
      hyprshot
      hyprpicker
      swww
      waypaper
      rofi-wayland
      cliphist
      wl-clipboard
      swaynotificationcenter
      network-manager-applet
      blueman
      brightnessctl
      playerctl
      galculator
      pavucontrol
      lxqt.lxqt-policykit
      kdePackages.kwallet
      qt6ct
    ];

    # ── Session variables ────────────────────────────────────────────────────
    # NOTE: Do NOT put secrets (API tokens, etc.) here — use sops-nix or agenix.
    home.sessionVariables = {
      XCURSOR_SIZE                 = "24";
      HYPRCURSOR_SIZE              = "24";
      QT_QPA_PLATFORMTHEME         = "qt6ct";
      OZONE_PLATFORM               = "wayland";
      MOZ_ENABLE_WAYLAND           = "1";
      QT_QPA_PLATFORM              = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      HYPRSHOT_DIR                 = cfg.screenshotDir;
    };

    # ── Hyprland ─────────────────────────────────────────────────────────────
    # systemd.enable is left false — UWSM (configured in NixOS) handles the
    # session targets. Remove that concern if you stop using withUWSM.
    wayland.windowManager.hyprland = {
      enable          = true;
      xwayland.enable = true;
      systemd.enable  = false;

      # The entire config lives in extraConfig so the pywal source directive
      # can appear at the top before any variable references.
      extraConfig = ''
        # ── Per-machine: monitors & scaling ───────────────────────────────────
        # Override this in each host's home.nix via desktop.hyprland-desktop.monitors
        ${cfg.monitors}

        # ── Pywal colours (runtime-generated) ────────────────────────────────
        source = ${home}/.cache/wal/colors-hyprland.conf

        # ── Variables ─────────────────────────────────────────────────────────
        $terminal    = ${cfg.terminal}
        $fileManager = ${cfg.fileManager}
        $lockScreen  = ${cfg.lockScreen}
        $menu        = rofi -show drun -show-icons -sort -sorting-method fzf -matching normal -drun-match-fields name,comment,generic,exec,keywords
        $webBrowser  = MOZ_ENABLE_WAYLAND=1 firefox

        # ── Autostart ─────────────────────────────────────────────────────────
        exec-once = thunar --daemon
        exec-once = waybar
        exec-once = swww-daemon
        exec-once = nm-applet --indicator & blueman-applet &
        exec-once = kwalletd6
        exec-once = swaync
        exec-once = [workspace special:mail silent]  thunderbird
        exec-once = [workspace special:notes silent] obsidian
        exec-once = wl-paste --type text  --watch cliphist store
        exec-once = wl-paste --type image --watch cliphist store

        # ── Input ─────────────────────────────────────────────────────────────
        input {
            kb_layout          = cz,us
            kb_options         = grp:win_space_toggle
            numlock_by_default = true
            follow_mouse       = 1
            sensitivity        = -0.5
            accel_profile      = flat

            touchpad {
                natural_scroll = true
                scroll_factor  = 0.50
            }
        }

        gestures {
            workspace_swipe_distance = 200
            workspace_swipe_forever  = false
            gesture                  = 3, horizontal, workspace
            gesture                  = 3, vertical,   fullscreen
            workspace_swipe_use_r    = true
        }

        # Per-device overrides
        device {
            name        = aet-ms480bbt1-mouse
            sensitivity = -0.5
        }
        device {
            name        = syna3109:00-06cb:cea3-touchpad
            sensitivity = 0
        }
        device {
            name        = elan06fa:00-04f3:3293-touchpad
            sensitivity = 0
        }

        # ── Appearance ────────────────────────────────────────────────────────
        general {
            gaps_in              = 2
            gaps_out             = 2
            border_size          = 3
            col.active_border    = $color1 $color4 45deg
            col.inactive_border  = rgba(595959aa)
            resize_on_border     = true
            hover_icon_on_border = true
            allow_tearing        = false
            layout               = dwindle
        }

        decoration {
            rounding         = 10
            active_opacity   = 1
            inactive_opacity = 1

            shadow {
                enabled      = true
                range        = 4
                render_power = 3
                color        = rgba(1a1a1aee)
            }

            blur {
                enabled  = true
                size     = 5
                passes   = 2
                vibrancy = 0.1696
            }
        }

        animations {
            enabled = yes, please :)

            bezier = easeOutQuint,    0.23, 1,    0.32, 1
            bezier = easeInOutCubic,  0.65, 0.05, 0.36, 1
            bezier = linear,          0,    0,    1,    1
            bezier = almostLinear,    0.5,  0.5,  0.75, 1.0
            bezier = quick,           0.15, 0,    0.1,  1

            animation = global,         1, 10,   default
            animation = border,         1,  5.39, easeOutQuint
            animation = windows,        1,  4.79, easeOutQuint
            animation = windowsIn,      1,  4.1,  easeOutQuint, popin 87%
            animation = windowsOut,     1,  1.49, linear,       popin 87%
            animation = fadeIn,         1,  1.73, almostLinear
            animation = fadeOut,        1,  1.46, almostLinear
            animation = fade,           1,  3.03, quick
            animation = layers,         1,  3.81, easeOutQuint
            animation = layersIn,       1,  4,    easeOutQuint, fade
            animation = layersOut,      1,  1.5,  linear,       fade
            animation = fadeLayersIn,   1,  1.79, almostLinear
            animation = fadeLayersOut,  1,  1.39, almostLinear
            animation = workspaces,     1,  1.94, almostLinear, fade
            animation = workspacesIn,   1,  1.21, almostLinear, fade
            animation = workspacesOut,  1,  1.94, almostLinear, fade
        }

        # swaync blur
        layerrule = blur on, ignore_alpha 0.2, dim_around off, match:class swaync

        # ── Window rules ─────────────────────────────────────────────────────
        windowrule = match:title File Operation Progress,   float on, center on
        windowrule = match:initial_title ^Write:.*,         float on, center on
        windowrule = match:initial_title Calendar Reminders, float on, center on
        windowrule = match:title ^Extension:.*,             float on, center on
        windowrule = match:initial_title galculator,        float on, center on

        # ── Layouts ───────────────────────────────────────────────────────────
        dwindle {
            pseudotile     = true
            preserve_split = true
        }

        master {
            new_status = master
        }

        misc {
            focus_on_activate       = true
            force_default_wallpaper = 0
            disable_hyprland_logo   = true
        }

        workspace = w[t1], gapsout:0
        workspace = w[t1], border:0

        # ── Keybinds ─────────────────────────────────────────────────────────
        $mainMod = SUPER

        # Lid switch → lock + suspend
        bindl = , switch:on:Lid Switch, exec, $lockScreen & systemctl suspend

        # Core
        bind = $mainMod,       Q, exec,          $terminal
        bind = $mainMod,       C, killactive
        bind = $mainMod SHIFT, M, exec,          uwsm stop
        bind = $mainMod,       E, exec,          $fileManager
        bind = $mainMod,       O, togglefloating
        bind = $mainMod,       I, fullscreen
        bind = $mainMod,       R, exec,          $menu
        bind = $mainMod,       P, pseudo
        bind = $mainMod,       J, togglesplit
        bind = $mainMod,       F, exec,          $webBrowser
        bind = $mainMod SHIFT, F, exec,          $webBrowser --private-window
        bind = $mainMod,       L, exec,          $lockScreen
        bind = $mainMod,       W, exec,          hyprctl dispatch exec "[float;size 800 600;center] waypaper"
        bind = $mainMod,       N, exec,          swaync-client -t

        # Clipboard (cliphist + rofi)
        bind = $mainMod,       V, exec, cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy
        bind = $mainMod SHIFT, V, exec, cliphist wipe

        # Focus
        bind = $mainMod, left,  movefocus, l
        bind = $mainMod, right, movefocus, r
        bind = $mainMod, up,    movefocus, u
        bind = $mainMod, down,  movefocus, d

        # Workspaces 1-10
        bindl = $mainMod, code:10, workspace, 1
        bindl = $mainMod, code:11, workspace, 2
        bindl = $mainMod, code:12, workspace, 3
        bindl = $mainMod, code:13, workspace, 4
        bindl = $mainMod, code:14, workspace, 5
        bindl = $mainMod, code:15, workspace, 6
        bindl = $mainMod, code:16, workspace, 7
        bindl = $mainMod, code:17, workspace, 8
        bindl = $mainMod, code:18, workspace, 9
        bindl = $mainMod, code:19, workspace, 10

        # Workspaces 11-20 (Alt layer)
        bindl = $mainMod ALT, code:10, workspace, 11
        bindl = $mainMod ALT, code:11, workspace, 12
        bindl = $mainMod ALT, code:12, workspace, 13
        bindl = $mainMod ALT, code:13, workspace, 14
        bindl = $mainMod ALT, code:14, workspace, 15
        bindl = $mainMod ALT, code:15, workspace, 16
        bindl = $mainMod ALT, code:16, workspace, 17
        bindl = $mainMod ALT, code:17, workspace, 18
        bindl = $mainMod ALT, code:18, workspace, 19
        bindl = $mainMod ALT, code:19, workspace, 20

        # Relative workspace navigation (- / =)
        bindl = $mainMod, code:20, workspace, e-1
        bindl = $mainMod, code:21, workspace, e+1

        # Move window to workspace 1-10
        bind = $mainMod SHIFT, code:10, movetoworkspace, 1
        bind = $mainMod SHIFT, code:11, movetoworkspace, 2
        bind = $mainMod SHIFT, code:12, movetoworkspace, 3
        bind = $mainMod SHIFT, code:13, movetoworkspace, 4
        bind = $mainMod SHIFT, code:14, movetoworkspace, 5
        bind = $mainMod SHIFT, code:15, movetoworkspace, 6
        bind = $mainMod SHIFT, code:16, movetoworkspace, 7
        bind = $mainMod SHIFT, code:17, movetoworkspace, 8
        bind = $mainMod SHIFT, code:18, movetoworkspace, 9
        bind = $mainMod SHIFT, code:19, movetoworkspace, 10

        # Move window to workspace 11-20 (Alt layer)
        bind = $mainMod SHIFT ALT, code:10, movetoworkspace, 11
        bind = $mainMod SHIFT ALT, code:11, movetoworkspace, 12
        bind = $mainMod SHIFT ALT, code:12, movetoworkspace, 13
        bind = $mainMod SHIFT ALT, code:13, movetoworkspace, 14
        bind = $mainMod SHIFT ALT, code:14, movetoworkspace, 15
        bind = $mainMod SHIFT ALT, code:15, movetoworkspace, 16
        bind = $mainMod SHIFT ALT, code:16, movetoworkspace, 17
        bind = $mainMod SHIFT ALT, code:17, movetoworkspace, 18
        bind = $mainMod SHIFT ALT, code:18, movetoworkspace, 19
        bind = $mainMod SHIFT ALT, code:19, movetoworkspace, 20

        # Move window between monitors
        bind = $mainMod SHIFT, left,  movewindow, l
        bind = $mainMod SHIFT, right, movewindow, r
        bind = $mainMod SHIFT, up,    movewindow, u
        bind = $mainMod SHIFT, down,  movewindow, d

        # Move workspace to monitor
        bind = $mainMod CTRL SHIFT, left,  movecurrentworkspacetomonitor, l
        bind = $mainMod CTRL SHIFT, right, movecurrentworkspacetomonitor, r

        # Special workspaces
        bind = $mainMod,       S, togglespecialworkspace, notes
        bind = $mainMod SHIFT, S, movetoworkspace,        special:notes
        bind = $mainMod,       X, togglespecialworkspace, dashboard
        bind = $mainMod SHIFT, X, movetoworkspace,        special:dashboard
        bind = $mainMod,       T, togglespecialworkspace, mail
        bind = $mainMod SHIFT, T, movetoworkspace,        special:mail

        # Scroll / Ctrl+arrow workspace navigation
        bind = $mainMod, mouse_down, workspace, e+1
        bind = $mainMod, mouse_up,   workspace, e-1
        bind = $mainMod CTRL, right, workspace, +1
        bind = $mainMod CTRL, left,  workspace, -1

        # Mouse move/resize
        bindm = $mainMod, mouse:272, movewindow
        bindm = $mainMod, mouse:273, resizewindow

        # Media / brightness / volume
        bindel = , XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@   5%+
        bindel = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@   5%-
        bindel = , XF86AudioMute,         exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle
        bindel = , XF86AudioMicMute,      exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle
        bindel = , XF86MonBrightnessUp,   exec, brightnessctl -e set 5%+
        bindel = , XF86MonBrightnessDown, exec, brightnessctl -e set 5%-
        bindel = , XF86Calculator,        exec, galculator
        bindl  = , XF86AudioNext,         exec, playerctl next
        bindl  = , XF86AudioPause,        exec, playerctl play-pause
        bindl  = , XF86AudioPlay,         exec, playerctl play-pause
        bindl  = , XF86AudioPrev,         exec, playerctl previous

        # Screenshot (region)
        bind = , PRINT, exec, hyprshot -m region
      '';
    };

    # ── Waybar ────────────────────────────────────────────────────────────────
    programs.waybar = {
      enable   = true;
      settings = [{
        position        = "top";
        layer           = "top";
        exclusive       = true;
        passthrough     = false;
        gtk-layer-shell = true;
        margin-top      = 0;
        margin-left     = 5;
        margin-right    = 5;
        height          = 1;

        modules-left   = [ "cpu" "memory" "disk" "power-profiles-daemon" "battery" ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right  = [
          "tray"
          "custom/dropdown"
          "hyprland/language"
          "pulseaudio"
          "pulseaudio#microphone"
          "custom/separator1"
          "clock"
          "custom/separator2"
        ];

        battery = {
          states          = { good = 95; warning = 20; critical = 10; };
          format          = "{icon} <span color='#777777'>{capacity}%</span>";
          format-charging = " <span color='#777777'>{capacity}%</span>";
          format-discharging = "{icon} <span color='#777777'>{capacity}%</span>";
          format-icons    = [ "" "" "" "" "" ];
          interval        = 1;
        };

        tray = { icon-size = 16; spacing = 8; };

        "custom/spacer"     = { format = " "; tooltip = false; };
        "custom/separator1" = { format = ""; tooltip = false; };
        "custom/separator2" = { format = ""; tooltip = false; };

        "hyprland/window" = {
          format           = "{}";
          max-length       = 35;
          rewrite          = { "" = "Desktop"; };
          separate-outputs = true;
        };

        "hyprland/workspaces" = {
          format       = "{name}";
          on-click     = "activate";
          format-icons = {
            "1" = ""; "2" = ""; "3" = ""; "4" = ""; "5" = "";
            "6" = ""; "7" = ""; "8" = ""; "9" = "";
            active = ""; urgent = ""; persistent = ""; focused = ""; default = "";
          };
          sort-by-number = true;
        };

        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format         = "{:%H:%M:%S}";
          format-alt     = "{:%Y-%m-%d %H:%M:%S}";
          interval       = 1;
        };

        cpu = {
          states           = { warning = 90; };
          format           = "󰍛 <span color='#777777'>{usage}%</span>";
          interval         = 1;
          format-alt-click = "click";
          format-alt       = "󰍛 <span color='#777777'>{usage}% {avg_frequency}GHz</span>";
          on-click         = "btop";
        };

        memory = {
          states   = { warning = 90; };
          interval = 1;
          format   = " <span color='#777777'>{used:0.1f}GiB</span>";
        };

        pulseaudio = {
          format           = "{icon} <span color='#777777'>{volume}%</span>";
          format-bluetooth = "{icon} <span color='#777777'>{volume}%</span>";
          tooltip          = false;
          format-muted     = "<span color='#ff5555'>󰝟 --%</span>";
          on-click         = "wpctl set-mute @DEFAULT_SINK@ toggle";
          on-click-right   = "pavucontrol";
          on-scroll-up     = "wpctl set-volume @DEFAULT_SINK@ 10%+";
          on-scroll-down   = "wpctl set-volume @DEFAULT_SINK@ 10%-";
          format-icons     = {
            headphone  = "";
            hands-free = "";
            headset    = "";
            phone      = "";
            portable   = "";
            car        = "";
            default    = [ "" "" " " ];
          };
        };

        "pulseaudio#microphone" = {
          format              = "{format_source}";
          format-source       = " <span color='#777777'>{volume}%</span>";
          format-source-muted = "<span color='#ff5555'>󰍭 --%</span>";
          on-click            = "wpctl set-mute @DEFAULT_SOURCE@ toggle";
          on-scroll-up        = "wpctl set-volume @DEFAULT_SOURCE@ 5%+";
          on-scroll-down      = "wpctl set-volume @DEFAULT_SOURCE@ 5%-";
        };

        "hyprland/language" = {
          format    = "󰌌 <span color='#777777'>{}</span>";
          format-cs = "CZ";
          format-en = "US";
        };

        disk = {
          states   = { warning = 90; };
          interval = 10;
          path     = "/home";
          format   = " <span color='#777777'>{free}</span>";
          unit     = "GB";
        };

        power-profiles-daemon = {
          format         = "{icon}";
          tooltip-format = "Power profile: {profile}";
          tooltip        = true;
          format-icons   = {
            default     = "󰑣";
            performance = "󰑣";
            balanced    = "󰗑";
            power-saver = "";
          };
        };

        "custom/dropdown" = {
          format     = "  ";
          tooltip    = false;
          min-height = 1;
          class      = "dropdown";
          on-click   = "swaync-client -t";
        };
      }];

      # Pywal colours are imported at runtime via @import — the absolute path
      # resolves correctly as long as pywal has been run at least once.
      style = ''
        @import url("${home}/.cache/wal/colors-waybar.css");

        * {
            border:        none;
            border-radius: 10px;
            font-family:   "JetBrainsMono Nerd Font";
            font-weight:   bold;
            font-size:     14px;
            min-height:    0;
            opacity:       1;
        }

        window#waybar {
            background: transparent;
        }

        tooltip {
            background:    @background;
            border-radius: 10px;
            border-width:  2px;
            border-style:  solid;
            border-color:  @color1;
            padding-right: 7px;
            padding-left:  7px;
            padding-top:   5px;
            padding-bottom: 5px;
        }

        #workspaces button {
            color:         @color2;
            margin-right:  0px;
            padding-right: 4px;
            padding-left:  4px;
        }

        #workspaces button.active  { color: @color2; }

        #workspaces button.focused {
            color:         @color2;
            background:    #eba0ac;
            border-radius: 13px;
        }

        #workspaces button.persistent { color: #5d3874; }
        #workspaces button.empty      { color: #313244; }

        #workspaces button.active,
        #workspaces button.visible {
            color:         @background;
            background:    @color2;
            padding-left:  4px;
            padding-right: 4px;
            border-radius: 16px;
        }

        #workspaces button.urgent { color: @color6; }

        #language,
        #cpu,
        #window,
        #clock,
        #pulseaudio,
        #pulseaudio.microphone,
        #workspaces,
        #memory,
        #disk,
        #battery,
        #power-profiles-daemon,
        #tray {
            background:    @background;
            opacity:       0.9;
            padding:       1.5px 7px 1.5px 7px;
            margin-top:    5px;
            margin-bottom: 5px;
            border-radius: 13px;
            margin-right:  5px;
            margin-left:   5px;
            color:         @color2;
        }

        #workspaces {
            background:    @background;
            border-radius: 13px;
            margin-left:   5px;
            padding-right: 5px;
        }

        #window {
            border-radius: 7px;
            margin-left:   60px;
            margin-right:  60px;
        }

        #clock {
            color:         @color2;
            border-radius: 13px;
            margin-right:  0px;
            margin-left:   0px;
        }

        #memory {
            color:         @color2;
            border-radius: 0px;
            margin-left:   0px;
            margin-right:  0px;
        }
        #memory.warning { color: #ff5555; }

        #disk {
            color:         @color2;
            border-radius: 0px 13px 13px 0px;
            margin-left:   0px;
        }
        #disk.warning { color: #ff5555; }

        #cpu {
            color:         @color2;
            border-radius: 13px 0px 0px 13px;
            padding-left:  10px;
            margin-right:  0px;
            margin-left:   0px;
        }
        #cpu label  { color: @color2; }
        #cpu.warning { color: #ff5555; }

        #battery {
            border-radius: 13px;
            margin-left:   0px;
            margin-right:  0px;
            color:         @color2;
        }
        #battery.critical { color: #ff5555; }
        #battery.warning  { color: #ffae42; }
        #battery.good     { color: @color2; }

        #power-profiles-daemon {
            color:         @color2;
            border-radius: 13px 0px 0px 13px;
            margin-left:   0px;
            margin-right:  0px;
        }

        #pulseaudio {
            color:         @color2;
            border-radius: 0px;
            margin-right:  0px;
            margin-left:   0px;
        }

        #pulseaudio.microphone {
            color:         @color2;
            border-radius: 0px 13px 13px 0px;
            margin-left:   0px;
            margin-right:  5px;
        }

        #language {
            border-radius: 13px 0px 0px 13px;
            margin-right:  0px;
            color:         @color2;
        }

        #tray { border-radius: 13px; }

        #bluetooth {
            color:         #89b4fa;
            border-radius: 0px 13px 13px 0px;
            margin-left:   5px;
            margin-right:  5px;
        }

        #custom-dropdown {
            color:         @color2;
            background:    @background;
            opacity:       0.9;
            border-radius: 13px;
            margin-left:   4px;
            margin-right:  4px;
            margin-top:    5px;
            margin-bottom: 5px;
        }

        #network {
            color:         #f9e2af;
            border-radius: 7px;
            margin-right:  5px;
        }
      '';
    };

    # ── Hyprlock ──────────────────────────────────────────────────────────────
    # pywal $color* / $wallpaper / $foreground vars come from the source line.
    # extraConfig is appended after any generated settings — since we set no
    # settings{} here the file effectively IS just extraConfig.
    programs.hyprlock = {
      enable = true;
      extraConfig = ''
        source = ${home}/.cache/wal/colors-hyprland.conf

        $font = Monospace

        general {
            hide_cursor = true
        }

        animations {
            enabled = true
            bezier   = linear, 1, 1, 0, 0
            animation = fadeIn,          0, 5, linear
            animation = fadeOut,         1, 5, linear
            animation = inputFieldDots,  1, 2, linear
        }

        background {
            monitor     =
            path        = $wallpaper
            blur_passes = 2
        }

        input-field {
            monitor           =
            size              = 20%, 5%
            outline_thickness = 6
            inner_color       = rgba(10, 10, 10, 0.5)
            outer_color       = $color1 $color2 45deg
            check_color       = rgba(00ff99ee) rgba(ff6633ee) 45deg
            fail_color        = rgba(ff6633ee) rgba(ff0066ee) 45deg
            font_color        = $foreground
            fade_on_empty     = false
            rounding          = 15
            font_family       = $font
            placeholder_text  = Input password...
            fail_text         = $PAMFAIL
            dots_spacing      = 0.3
            position          = 0, -5%
            halign            = center
            valign            = center
        }

        # Clock
        label {
            monitor     =
            text        = $TIME
            font_size   = 90
            font_family = $font
            position    = 0, 10%
            halign      = center
            valign      = center
        }

        # Date
        label {
            monitor     =
            text        = cmd[update:60000] date +"%A, %d %B %Y"
            font_size   = 22
            font_family = $font
            position    = 0, 0%
            halign      = center
            valign      = center
        }

        # Keyboard layout indicator
        label {
            monitor   =
            text      = $LAYOUT[CZ,EN]
            font_size = 24
            onclick   = hyprctl switchxkblayout all next
            position  = 8.5%, -5%
            halign    = center
            valign    = center
        }
      '';
    };

    # ── Hypridle ──────────────────────────────────────────────────────────────
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd         = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd  = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout    = 300;   # 5 min — dim backlight
            on-timeout = "brightnessctl -s set 39900";
            on-resume  = "brightnessctl -r";
          }
          {
            timeout    = 600;   # 10 min — lock screen
            on-timeout = "loginctl lock-session";
          }
          {
            timeout    = 1200;  # 20 min — DPMS off
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on && brightnessctl -r";
          }
          {
            timeout    = 1800;  # 30 min — suspend
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };

    # ── Polkit agent ──────────────────────────────────────────────────────────
    # NOTE: Remove the equivalent systemd.user.services.polkit-agent block
    # from your NixOS configuration.nix when you enable this module, or
    # you will get a conflict between the two service definitions.
    systemd.user.services.polkit-agent = {
      Unit = {
        Description = "Polkit Authentication Agent";
        After       = "graphical-session.target";
        PartOf      = "graphical-session.target";
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
        Restart   = "on-failure";
      };
    };
  };
}

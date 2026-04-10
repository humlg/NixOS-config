{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;
in
{
  config = lib.mkIf cfg.enable {

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

        modules-left   = [ "cpu" "memory" "custom/disk" "power-profiles-daemon" "battery" ];
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
          format-charging = "󰂄 <span color='#777777'>{capacity}%</span>";
          format-discharging = "{icon} <span color='#777777'>{capacity}%</span>";
          format-icons    = [ "󰁺" "󰁻" "󰁽" "󰂀" "󰁹" ];
          interval        = 1;
        };

        tray = { icon-size = 16; spacing = 8; reverse-direction = true; };

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
          format         = "{:%Y-%m-%d %H:%M:%S}";
          format-alt     = "{:%H:%M:%S}";
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
            headphone  = "󰋋";
            hands-free = "󰋎";
            headset    = "󰋎";
            phone      = "󰏲";
            portable   = "󰏲";
            car        = "󰄋";
            default    = [ "󰕿" "󰖀" "󰕾" ];
          };
        };

        "pulseaudio#microphone" = {
          format              = "{format_source}";
          format-source       = "󰍬 <span color='#777777'>{volume}%</span>";
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

        "custom/disk" = {
          exec     = "df -BG --output=used,size /home | tail -1 | awk '{gsub(/G/,\"\"); printf \"%d/%dGiB\", $1, $2}'";
          interval = 1;
          format   = "󰋊 <span color='#777777'>{}</span>";
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
          format     = " 󰋼 ";
          tooltip    = false;
          min-height = 1;
          class      = "dropdown";
          on-click   = "swaync-client -R && swaync-client -t";
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
        #custom-disk,
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

        #custom-disk {
            color:         @color2;
            border-radius: 0px 13px 13px 0px;
            margin-left:   0px;
        }

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
  };
}

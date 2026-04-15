{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;
in
{
  config = lib.mkIf cfg.enable {

    # ── Hyprlock ──────────────────────────────────────────────────────────────
    # wallust $color* / $wallpaper / $foreground vars come from the source line.
    # extraConfig is appended after any generated settings — since we set no
    # settings{} here the file effectively IS just extraConfig.
    programs.hyprlock = {
      enable = true;
      extraConfig = ''
        source = ${home}/.cache/wallust/colors-hyprland.conf

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
  };
}

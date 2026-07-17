{ config, lib, ... }:

let
  cfg = config.programs.kitty;
in
{
  config = lib.mkIf cfg.enable {
    # Static theme: "Constant Perceptual Luminosity (dark)" by Aaron Hall (MIT).
    # ANSI colors picked in OKHSL to hold constant perceptual luminosity per
    # slot (.4 normal / .6 bright, .5 white / .7 bright white) so every color
    # stays readable on a dark background — deliberately not wallust-driven,
    # since wallpaper-derived colors were inconsistently readable.
    programs.kitty.settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.9";
      allow_remote_control = "yes";

      foreground = "#777777";
      background = "#000000";
      selection_foreground = "#745b00";
      selection_background = "#464646";

      mark1_foreground = "#000000";
      mark1_background = "#3123ff";
      mark2_foreground = "#000000";
      mark2_background = "#745b00";
      mark3_foreground = "#000000";
      mark3_background = "#9b0097";

      color0 = "#000000";
      color1 = "#b10b00";
      color2 = "#007232";
      color3 = "#745b00";
      color4 = "#3123ff";
      color5 = "#9b0097";
      color6 = "#006a78";
      color7 = "#777777";
      color8 = "#464646";
      color9 = "#ff3d2b";
      color10 = "#00ae50";
      color11 = "#b18c00";
      color12 = "#6786ff";
      color13 = "#eb00e4";
      color14 = "#00a3b7";
      color15 = "#ababab";
    };
  };
}

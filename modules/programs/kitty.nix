{ config, lib, ... }:

let
  cfg = config.programs.kitty;
in
{
  config = lib.mkIf cfg.enable {
    # Static theme: "Darkside" (kitty-themes, kovidgoyal/kitty-themes) —
    # deliberately not wallust-driven, since wallpaper-derived colors were
    # inconsistently readable.
    programs.kitty.settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.9";
      allow_remote_control = "yes";

      foreground = "#b9b9b9";
      background = "#212324";
      cursor = "#bbbbbb";
      selection_foreground = "#212324";
      selection_background = "#2f3333";

      active_tab_foreground = "#eeeeee";
      active_tab_background = "#2f3333";
      inactive_tab_foreground = "#b9b9b9";
      inactive_tab_background = "#1a1c1d";

      color0 = "#000000";
      color1 = "#e8331c";
      color2 = "#68c156";
      color3 = "#f1d32b";
      color4 = "#1c98e8";
      color5 = "#8e69c8";
      color6 = "#1c98e8";
      color7 = "#b9b9b9";
      color8 = "#000000";
      color9 = "#df5a4f";
      color10 = "#76b768";
      color11 = "#eed64a";
      color12 = "#387bd2";
      color13 = "#957bbd";
      color14 = "#3d96e2";
      color15 = "#b9b9b9";
    };
  };
}

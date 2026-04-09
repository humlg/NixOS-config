{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  config = lib.mkIf cfg.enable {

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
  };
}

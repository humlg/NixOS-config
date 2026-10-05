{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;

  # Gates idle-timeout listeners only, not before_sleep_cmd — docs/architecture.md.
  runUnlessIdleInhibited = pkgs.writeShellScript "hypridle-run-unless-inhibited" ''
    [ -f "$XDG_RUNTIME_DIR/hypridle-idle-inhibited" ] || exec "$@"
  '';
  guarded = cmd: "${runUnlessIdleInhibited} ${cmd}";

  # External-Lua dispatch form required under the Lua config — docs/architecture.md.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  # Inert under Noctalia — its own idle service owns idle/dim/lock/dpms/sleep. docs/maintenance.md #19.
  config = lib.mkIf (cfg.enable && !cfg.useNoctalia) {

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          # Under Noctalia, route through its IPC lock instead of spawning hyprlock
          # directly, to avoid both implementing the session-lock protocol at once.
          lock_cmd         = if cfg.useNoctalia
            then "noctalia msg session lock"
            else "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd  = dpms "on";
        };

        listener = [
          {
            timeout    = 300;   # 5 min — dim backlight
            on-timeout = guarded "brightnessctl -s set 39900";
            on-resume  = "brightnessctl -r";
          }
          {
            timeout    = 600;   # 10 min — lock screen
            on-timeout = guarded "loginctl lock-session";
          }
          {
            timeout    = 1200;  # 20 min — DPMS off
            on-timeout = guarded (dpms "off");
            on-resume  = "${dpms "on"} && brightnessctl -r";
          }
          {
            timeout    = 1800;  # sleep; command is host-configurable via sleepCommand
            on-timeout = guarded cfg.sleepCommand;
          }
        ];
      };
    };
  };
}

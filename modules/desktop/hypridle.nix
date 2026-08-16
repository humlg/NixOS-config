{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;

  # Idle-timeout listeners are gated on this flag file so the "sleep inhibit"
  # toggle (modules/desktop/swaync.nix) can disable *just* the idle timeouts
  # while leaving hypridle running — it must keep running so before_sleep_cmd
  # still locks the session on a lid-close-triggered suspend (handled directly
  # by logind, independent of hypridle's own listeners).
  runUnlessIdleInhibited = pkgs.writeShellScript "hypridle-run-unless-inhibited" ''
    [ -f "$XDG_RUNTIME_DIR/hypridle-idle-inhibited" ] || exec "$@"
  '';
  guarded = cmd: "${runUnlessIdleInhibited} ${cmd}";
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
          after_sleep_cmd  = "sh -c 'hyprctl dispatch dpms on'";
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
            on-timeout = guarded "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on && brightnessctl -r";
          }
          {
            # 30 min — sleep. The exact command is host-configurable via
            # desktop.hyprland-desktop.sleepCommand: saruman uses
            # suspend-then-hibernate here so this listener matches its lid-close
            # and power-key paths (both handled in its configuration.nix via
            # logind), rather than leaving the machine suspended indefinitely on
            # a kernel whose deepest sleep state is patched out.
            timeout    = 1800;
            on-timeout = guarded cfg.sleepCommand;
          }
        ];
      };
    };
  };
}

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

  # All hosts run the Lua config (desktop.hyprland-desktop.useLuaConfig), where
  # hyprctl hands its dispatch argument to Lua rather than to the hyprlang
  # dispatcher parser. The bare `hyprctl dispatch dpms on` spelling therefore
  # fails to parse ("')' expected near 'on'") and the panel never comes back —
  # silently, because hypridle doesn't check exit status. Same external-Lua form
  # as hyprland-config-lua/autostart.nix uses.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  # Gated the same way as ags.nix/swaync.nix (Phase C of the Noctalia
  # migration, maintenance.md item 19): Noctalia owns idle/dim/lock/dpms/sleep
  # entirely on hosts that pilot it, via its own idle service configured
  # outside Nix. Running hypridle's listeners alongside it would race the same
  # way the compositor and logind once raced over lid-switch sleep (item 7's
  # first attempt) — two independent daemons both listening for the same idle
  # events, only one of which can win unpredictably.
  config = lib.mkIf (cfg.enable && !cfg.useNoctalia) {

    # ── Hypridle ──────────────────────────────────────────────────────────────
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          # Under Noctalia (Phase D of the migration, see maintenance.md item
          # 19), lock_cmd must not spawn hyprlock at all: Noctalia also
          # implements the session-lock protocol, and running both risks a
          # race for the lock surface. Use Noctalia's documented IPC lock
          # command instead, so hyprlock is never invoked automatically on
          # this host again. hyprlock.nix itself stays enabled/untouched so
          # this is a one-line rollback if Noctalia's lock proves unreliable.
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
            # 30 min — sleep. The exact command is host-configurable via
            # desktop.hyprland-desktop.sleepCommand, so this listener always
            # matches the host's lid-close and power-key paths (handled by
            # logind in its configuration.nix).
            timeout    = 1800;
            on-timeout = guarded cfg.sleepCommand;
          }
        ];
      };
    };
  };
}

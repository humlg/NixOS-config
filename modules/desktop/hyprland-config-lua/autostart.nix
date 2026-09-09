{ cfg, lib, ... }:
let
  # Nested dispatch: the workspace is assigned as part of the launch itself,
  # before the window ever maps, so there's no flash. The command must be a
  # literal here (not the Lua variable from variables.nix) because this text
  # is shelled out to a second `hyprctl dispatch` process that parses it as
  # its own standalone Lua chunk — it doesn't share this config's scope.
  silentLaunches = lib.concatMapStrings (a: ''
    hl.exec_cmd([[sleep ${toString a.delay} && hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:${a.workspace} silent] ${a.command}")']])
  '') cfg.silentApps;

  maxDelay = lib.foldl' lib.max 0 (map (a: a.delay) cfg.silentApps);

  # State-checked cleanup: find whichever special workspaces are actually
  # shown right now (per-monitor, via `hyprctl monitors -j`) and toggle
  # exactly those closed. Safe to run repeatedly / when nothing is shown —
  # unlike blindly toggling every silentApps workspace, which would
  # incorrectly *open* any that were never revealed.
  cleanupShownSpecials = ''hyprctl monitors -j | jq -r '.[].specialWorkspace.name | select(. != "")' | sed 's/^special://' | xargs -r -n1 hyprctl dispatch togglespecialworkspace'';

  focusBack = lib.optionalString (cfg.silentApps != [ ]) ''
    -- no_initial_focus (window-rules.nix) only stops these from stealing focus
    -- from an ALREADY-focused window; at boot there's nothing else focused
    -- yet, so Hyprland falls back to focusing them anyway — and focusing a
    -- window on a hidden special workspace reveals that workspace as an
    -- on-screen overlay. Switching the active regular workspace back to 1
    -- does NOT auto-close an already-revealed special workspace overlay —
    -- that's a known Hyprland limitation (hyprwm/Hyprland#4400, #7662),
    -- there's no "hide" dispatcher, only a stateful toggle — so after
    -- refocusing, run the state-checked cleanup above.
    hl.exec_cmd([[sleep ${toString (maxDelay + 2)} && hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'; ${cleanupShownSpecials}]])
    -- Slow-starting apps (Thunderbird's account/OAuth handshake in
    -- particular) can map and get focus-revealed well after the pass above
    -- already ran. Re-run the same idempotent cleanup a couple more times
    -- as a cheap catch-all instead of guessing a single "safe enough" delay.
    hl.exec_cmd([[sleep ${toString (maxDelay + 5)}  && ${cleanupShownSpecials}]])
    hl.exec_cmd([[sleep ${toString (maxDelay + 12)} && ${cleanupShownSpecials}]])
  '';
in
''
  -- ── Autostart ───────────────────────────────────────────────────
  hl.on("hyprland.start", function()
    hl.exec_cmd("thunar --daemon")
    ${if cfg.useNoctalia then "" else ''hl.exec_cmd("ags run")''}
    hl.exec_cmd("awww-daemon")
    ${if cfg.useNoctalia then "" else ''hl.exec_cmd("sleep 1 && waypaper --restore")''}
${silentLaunches}${focusBack}
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
  end)
''

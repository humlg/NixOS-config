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

  focusBack = lib.optionalString (cfg.silentApps != [ ]) ''
    -- no_initial_focus (window-rules.nix) only stops these from stealing focus
    -- from an ALREADY-focused window; at boot there's nothing else focused
    -- yet, so Hyprland falls back to focusing them anyway. Force focus back
    -- to the default workspace once all silent apps have had time to map.
    hl.exec_cmd([[sleep ${toString (maxDelay + 2)} && hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })']])
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

{ cfg, lib, ... }:
let
  # Mechanism explained in full in docs/architecture.md ("Silent autostart into special workspaces").
  silentLaunches = lib.concatMapStrings (a: ''
    hl.exec_cmd([[sleep ${toString a.delay} && hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:${a.workspace} silent] ${a.command}")']])
  '') cfg.silentApps;

  maxDelay = lib.foldl' lib.max 0 (map (a: a.delay) cfg.silentApps);

  cleanupShownSpecials = ''hyprctl monitors -j | jq -r '.[].specialWorkspace.name | select(. != "")' | sed 's/^special://' | xargs -r -n1 hyprctl dispatch togglespecialworkspace'';

  focusBack = lib.optionalString (cfg.silentApps != [ ]) ''
    hl.exec_cmd([[sleep ${toString (maxDelay + 2)} && hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'; ${cleanupShownSpecials}]])
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

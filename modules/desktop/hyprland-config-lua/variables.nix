{ cfg, lib, ... }:
let
  silentAppVars = lib.concatMapStrings (a: ''
    local ${a.name} = "${a.command}"
  '') cfg.silentApps;
in
''
  -- ── Variables ───────────────────────────────────────────────────
  local terminal    = "${cfg.terminal}"
  local fileManager = "${cfg.fileManager}"
  local lockScreen  = "${cfg.lockScreen}"
  local menu        = "anyrun"
  local webBrowser  = "MOZ_ENABLE_WAYLAND=1 zen"
  local mainMod     = "SUPER"

  -- Silent-workspace autostart apps (desktop.hyprland-desktop.silentApps)
${silentAppVars}''

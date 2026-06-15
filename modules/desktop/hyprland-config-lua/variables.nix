{ cfg, ... }:
''
  -- ── Variables ───────────────────────────────────────────────────
  local terminal    = "${cfg.terminal}"
  local fileManager = "${cfg.fileManager}"
  local lockScreen  = "${cfg.lockScreen}"
  local menu        = "anyrun"
  local webBrowser  = "MOZ_ENABLE_WAYLAND=1 zen"
  local mainMod     = "SUPER"
''

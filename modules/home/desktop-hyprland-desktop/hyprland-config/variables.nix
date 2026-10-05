{ cfg, ... }:
''
  # ── Variables ───────────────────────────────────────────────────
  $terminal    = ${cfg.terminal}
  $fileManager = ${cfg.fileManager}
  $lockScreen  = ${cfg.lockScreen}
  $menu        = anyrun
  $webBrowser  = MOZ_ENABLE_WAYLAND=1 zen
''

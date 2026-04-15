{ cfg, ... }:
''
  # ── Variables ───────────────────────────────────────────────────
  $terminal    = ${cfg.terminal}
  $fileManager = ${cfg.fileManager}
  $lockScreen  = ${cfg.lockScreen}
  $menu        = albert toggle
  $webBrowser  = MOZ_ENABLE_WAYLAND=1 firefox
''

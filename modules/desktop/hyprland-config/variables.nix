{ cfg, ... }:
''
  # ── Variables ───────────────────────────────────────────────────
  $terminal    = ${cfg.terminal}
  $fileManager = ${cfg.fileManager}
  $lockScreen  = ${cfg.lockScreen}
  $menu        = rofi -show drun -show-icons -sort -sorting-method fzf -matching normal -drun-match-fields name,comment,generic,exec,keywords
  $webBrowser  = MOZ_ENABLE_WAYLAND=1 firefox
''

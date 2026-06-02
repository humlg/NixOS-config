{ ... }:
''
  # ── Layouts ─────────────────────────────────────────────────────
  dwindle {
      preserve_split = true
  }

  master {
      new_status = master
  }

  misc {
      focus_on_activate       = true
      force_default_wallpaper = 0
      disable_hyprland_logo   = true
  }

  workspace = w[t1], gapsout:0, gapsin:0, border:0
  windowrule = border_size 0, rounding 0, match:float 0, match:workspace w[t1]
''

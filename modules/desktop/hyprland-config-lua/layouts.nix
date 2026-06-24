{ ... }:
''
  -- ── Layouts ─────────────────────────────────────────────────────
  hl.config({
    dwindle = {
      preserve_split = true,
    },
    master = {
      new_status = "master",
    },
    misc = {
      focus_on_activate       = true,
      force_default_wallpaper = 0,
      disable_hyprland_logo   = true,
    },
  })

  -- Tiled workspace: no borders or gaps
  hl.workspace_rule({
    workspace = "w[t1]",
    gapsout   = 0,
    gapsin    = 0,
    border    = 0,
  })
  hl.window_rule({
    match       = { float = false, workspace = "w[t1]" },
    border_size = 0,
    rounding    = 0,
  })
''

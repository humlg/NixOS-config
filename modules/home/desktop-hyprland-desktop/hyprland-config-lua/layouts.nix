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
    scrolling = {
      column_width             = 0.5,
      explicit_column_widths   = "0.333, 0.5, 0.667, 1.0",  -- cycled by colresize +conf/-conf
      fullscreen_on_one_column = true,
      follow_focus             = 1,
    },
    misc = {
      -- Global; stops xdg-activation focus-stealing (silentApps boot flash) — docs/architecture.md.
      focus_on_activate       = false,
      force_default_wallpaper = 0,
      disable_hyprland_logo   = true,
    },
  })

  -- Tiled workspace: no borders or gaps
  hl.workspace_rule({
    workspace   = "w[t1]",
    gaps_out    = 0,
    gaps_in     = 0,
    border_size = 0,
  })
  hl.window_rule({
    match       = { float = false, workspace = "w[t1]" },
    border_size = 0,
    rounding    = 0,
  })
''

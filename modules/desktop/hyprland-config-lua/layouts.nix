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
      -- false 2026-09-09 (was true): stops Hyprland honoring an app's own
      -- xdg-activation "focus me" request. This is a separate mechanism
      -- from the no_initial_focus window rule (which only covers
      -- Hyprland's own default new-window-focus behavior) — it's the
      -- likely actual cause of silentApps windows (desktop.hyprland-
      -- desktop.silentApps, see hyprland-config-lua/{autostart,window-
      -- rules}.nix) still revealing their special workspace at boot even
      -- with no_initial_focus set and the post-launch cleanup toggle in
      -- place. Global, so it also affects apps elsewhere that rely on
      -- activation to raise/refocus an already-running window (e.g.
      -- clicking a dock/taskbar icon a second time, or a notification
      -- raising its app) — watch for that regressing if this doesn't
      -- fully fix the boot flash either.
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

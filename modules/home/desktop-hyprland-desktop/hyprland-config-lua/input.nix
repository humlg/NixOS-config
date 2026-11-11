{ cfg, ... }:
let
  # Scrolling: horizontal swipe drags the strip live (native scroll_move, 2× finger speed) and snaps to a
  # column on release; vertical switches workspaces — docs/architecture.md.
  gestures = if cfg.layout == "scrolling" then ''
  hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move", scale = 2.0 })
  hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
'' else ''
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace"  })
  hl.gesture({ fingers = 3, direction = "vertical",   action = "fullscreen" })
'';
in
''
  -- ── Input ───────────────────────────────────────────────────────
  hl.config({
    input = {
      kb_layout          = "cz,us",
      kb_options         = "grp:win_space_toggle",
      numlock_by_default = true,
      follow_mouse       = 1,
      sensitivity        = -0.5,
      accel_profile      = "flat",
      touchpad = {
        natural_scroll = true,
        scroll_factor  = 0.50,
      },
    },
    gestures = {
      workspace_swipe_distance = 200,
      workspace_swipe_forever  = false,
      workspace_swipe_use_r    = true,
      scrolling = { move_snap_cursor = false },  -- scroll_move: leave cursor put on release
    },
  })

  -- hl.gesture() is the Lua equivalent of "gesture = ..." repeated keyword
${gestures}
  -- Per-device overrides
  hl.device({ name = "aet-ms480bbt1-mouse",            sensitivity = -0.5 })
  hl.device({ name = "syna3109:00-06cb:cea3-touchpad", sensitivity = 0    })
  hl.device({ name = "elan06fa:00-04f3:3293-touchpad", sensitivity = 0    })
''

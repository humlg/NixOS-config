{ ... }:
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
      -- TODO: verify list syntax for repeated gesture directives
      gesture = {
        "3, horizontal, workspace",
        "3, vertical,   fullscreen",
      },
    },
  })

  -- Per-device overrides
  hl.device({ name = "aet-ms480bbt1-mouse",            sensitivity = -0.5 })
  hl.device({ name = "syna3109:00-06cb:cea3-touchpad", sensitivity = 0    })
  hl.device({ name = "elan06fa:00-04f3:3293-touchpad", sensitivity = 0    })
''

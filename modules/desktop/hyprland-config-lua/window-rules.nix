{ ... }:
''
  -- ── Window rules ────────────────────────────────────────────────
  hl.window_rule({
    match     = { initial_class = "^(thunderbird)$" },
    workspace = "special:mail silent",
  })
  -- Electron 41 reports Wayland app_id as "electron" — match on title instead
  hl.window_rule({
    match     = { class = "^electron$", initial_title = "Obsidian" },
    workspace = "special:notes silent",
  })

  hl.window_rule({
    match  = { title = "File Operation Progress" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { initial_title = "^Write:.*" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { initial_title = "Calendar Reminders" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { title = "^Extension:.*" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { initial_class = "org.gnome.Calculator" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { initial_class = "Todoist" },
    float  = true,
    center = true,
  })
  hl.window_rule({
    match  = { initial_class = "mpv" },
    float  = true,
    center = true,
    size   = "1155 650",
  })
''

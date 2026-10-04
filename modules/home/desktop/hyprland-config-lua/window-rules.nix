{ cfg, lib, ... }:
let
  # class is a regex and may contain backslash escapes (e.g. "\." to match a
  # literal dot in a reverse-DNS app id) — embed it as a Lua long-bracket
  # string ([[...]]), which passes the text through verbatim, rather than a
  # quoted string, where Lua would try (and fail) to interpret "\." itself
  # as an escape sequence.
  silentAppRules = lib.concatMapStrings (a: ''
    hl.window_rule({
      match            = { ${if a.matchInitial then "initial_class" else "class"} = [[${a.class}]] },
      workspace        = "special:${a.workspace} silent",
      no_initial_focus = true,
    })
  '') cfg.silentApps;
in
''
  -- ── Window rules ────────────────────────────────────────────────
${silentAppRules}
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
  hl.window_rule({
    match  = { class = "^waypaper$" },
    float  = true,
    center = true,
    size   = "800 600",
  })
  hl.window_rule({
    match  = { initial_title = "^Steam$" },
    center = true,
  })
''

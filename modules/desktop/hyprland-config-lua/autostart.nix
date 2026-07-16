{ ... }:
''
  -- ── Autostart ───────────────────────────────────────────────────
  hl.on("hyprland.start", function()
    -- Greet on workspace 1 immediately so it's already the focused window
    -- once thunderbird/obsidian map -- gives no_initial_focus something to
    -- fall back to instead of stealing focus themselves.
    hl.exec_cmd("kitty --class kitty-startup")
    hl.exec_cmd("thunar --daemon")
    hl.exec_cmd("ags run")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && waypaper --restore")
    hl.exec_cmd("nm-applet --indicator & blueman-applet &")
    hl.exec_cmd([[sleep 3 && hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:mail silent] thunderbird")']])
    hl.exec_cmd([[sleep 4 && hyprctl dispatch 'hl.dsp.exec_cmd("[workspace special:notes silent] obsidian")']])
    -- no_initial_focus only stops these from stealing focus from an ALREADY-focused
    -- window; at boot there's nothing else focused yet, so Hyprland falls back to
    -- focusing them anyway. Force focus back to the default workspace once both
    -- have had time to map.
    hl.exec_cmd([[sleep 6 && hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })']])
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
  end)
''

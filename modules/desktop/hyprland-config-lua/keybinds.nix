{ reloadDesktop, ... }:
''
  -- ── Keybinds ────────────────────────────────────────────────────
  -- Flag reference: { locked=true } = bindl, { repeating=true } = binde,
  --                 { locked=true, repeating=true } = bindel, { mouse=true } = bindm

  -- Lid switch → lock + suspend
  hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(lockScreen .. " & systemctl suspend"), { locked = true })

  -- Core
  hl.bind(mainMod .. " + Q",           hl.dsp.exec_cmd(terminal))
  hl.bind(mainMod .. " + SHIFT + code:201", hl.dsp.exec_cmd(menu))
  hl.bind(mainMod .. " + C",           hl.dsp.window.close())
  hl.bind(mainMod .. " + SHIFT + M",   hl.dsp.exec_cmd("uwsm stop"))
  hl.bind(mainMod .. " + SHIFT + R",   hl.dsp.exec_cmd("${reloadDesktop}/bin/reload-desktop"))
  hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd(fileManager))
  hl.bind(mainMod .. " + O",           hl.dsp.window.float({ action = "toggle" }))
  hl.bind(mainMod .. " + I",           hl.dsp.window.fullscreen())
  hl.bind(mainMod .. " + R",           hl.dsp.exec_cmd(menu))
  hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())
  hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))
  hl.bind(mainMod .. " + F",           hl.dsp.exec_cmd(webBrowser))
  hl.bind(mainMod .. " + SHIFT + F",   hl.dsp.exec_cmd(webBrowser .. " --private-window"))
  hl.bind(mainMod .. " + L",           hl.dsp.exec_cmd(lockScreen))
  hl.bind(mainMod .. " + W",           hl.dsp.exec_cmd([[hyprctl dispatch exec "[float;size 800 600;center] waypaper"]]))
  hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("swaync-client -R && swaync-client -t"))
  hl.bind("ALT + TAB",                 hl.dsp.focus({ workspace = "previous" }))

  -- Clipboard (cliphist + rofi)
  hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"))
  hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))

  -- Focus
  hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
  hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
  hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
  hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

  -- Workspaces 1-10
  hl.bind(mainMod .. " + code:10", hl.dsp.focus({ workspace = 1  }), { locked = true })
  hl.bind(mainMod .. " + code:11", hl.dsp.focus({ workspace = 2  }), { locked = true })
  hl.bind(mainMod .. " + code:12", hl.dsp.focus({ workspace = 3  }), { locked = true })
  hl.bind(mainMod .. " + code:13", hl.dsp.focus({ workspace = 4  }), { locked = true })
  hl.bind(mainMod .. " + code:14", hl.dsp.focus({ workspace = 5  }), { locked = true })
  hl.bind(mainMod .. " + code:15", hl.dsp.focus({ workspace = 6  }), { locked = true })
  hl.bind(mainMod .. " + code:16", hl.dsp.focus({ workspace = 7  }), { locked = true })
  hl.bind(mainMod .. " + code:17", hl.dsp.focus({ workspace = 8  }), { locked = true })
  hl.bind(mainMod .. " + code:18", hl.dsp.focus({ workspace = 9  }), { locked = true })
  hl.bind(mainMod .. " + code:19", hl.dsp.focus({ workspace = 10 }), { locked = true })

  -- Workspaces 11-20 (Alt layer)
  hl.bind(mainMod .. " + ALT + code:10", hl.dsp.focus({ workspace = 11 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:11", hl.dsp.focus({ workspace = 12 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:12", hl.dsp.focus({ workspace = 13 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:13", hl.dsp.focus({ workspace = 14 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:14", hl.dsp.focus({ workspace = 15 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:15", hl.dsp.focus({ workspace = 16 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:16", hl.dsp.focus({ workspace = 17 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:17", hl.dsp.focus({ workspace = 18 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:18", hl.dsp.focus({ workspace = 19 }), { locked = true })
  hl.bind(mainMod .. " + ALT + code:19", hl.dsp.focus({ workspace = 20 }), { locked = true })

  -- Relative workspace navigation (- / =)
  hl.bind(mainMod .. " + code:20", hl.dsp.focus({ workspace = "e-1" }), { locked = true })
  hl.bind(mainMod .. " + code:21", hl.dsp.focus({ workspace = "e+1" }), { locked = true })

  -- Move window to workspace 1-10
  hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1  }))
  hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2  }))
  hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3  }))
  hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4  }))
  hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5  }))
  hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6  }))
  hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7  }))
  hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8  }))
  hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9  }))
  hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }))

  -- Move window to workspace 11-20 (Alt layer)
  hl.bind(mainMod .. " + SHIFT + ALT + code:10", hl.dsp.window.move({ workspace = 11 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:11", hl.dsp.window.move({ workspace = 12 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:12", hl.dsp.window.move({ workspace = 13 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:13", hl.dsp.window.move({ workspace = 14 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:14", hl.dsp.window.move({ workspace = 15 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:15", hl.dsp.window.move({ workspace = 16 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:16", hl.dsp.window.move({ workspace = 17 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:17", hl.dsp.window.move({ workspace = 18 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:18", hl.dsp.window.move({ workspace = 19 }))
  hl.bind(mainMod .. " + SHIFT + ALT + code:19", hl.dsp.window.move({ workspace = 20 }))

  -- Move window between monitors
  hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
  hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
  hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
  hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

  -- Move workspace to monitor
  hl.bind(mainMod .. " + CTRL + SHIFT + left",  hl.dsp.workspace.move_to_monitor("left"))
  hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.workspace.move_to_monitor("right"))

  -- Special workspaces
  hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("notes"))
  hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:notes" }))
  hl.bind(mainMod .. " + X",         hl.dsp.workspace.toggle_special("dashboard"))
  hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "special:dashboard" }))
  hl.bind(mainMod .. " + T",         hl.dsp.workspace.toggle_special("mail"))
  hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = "special:mail" }))

  -- Scroll / Ctrl+arrow workspace navigation
  hl.bind(mainMod .. " + mouse_down",   hl.dsp.focus({ workspace = "e+1" }))
  hl.bind(mainMod .. " + mouse_up",     hl.dsp.focus({ workspace = "e-1" }))
  hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "+1" }))
  hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "-1" }))

  -- Mouse move/resize
  hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
  hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

  -- Media / brightness / volume
  hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume --limit 1.5 @DEFAULT_AUDIO_SINK@   5%+"), { locked = true, repeating = true })
  hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@   5%-"),            { locked = true, repeating = true })
  hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle"),         { locked = true, repeating = true })
  hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"),         { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e set 5%+"),                               { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e set 5%-"),                               { locked = true, repeating = true })
  hl.bind("XF86Calculator",        hl.dsp.exec_cmd("gnome-calculator"),                                       { locked = true, repeating = true })
  hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),        { locked = true })
  hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
  hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
  hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

  -- Screenshot (region)
  hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
''

{ ... }:
''
  -- ── Autostart ───────────────────────────────────────────────────
  hl.on("hyprland.start", function()
    hl.exec_cmd("thunar --daemon")
    hl.exec_cmd("ags run")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && waypaper --restore")
    hl.exec_cmd("nm-applet --indicator & blueman-applet &")
    hl.exec_cmd("sleep 3 && hyprctl dispatch exec '[workspace special:mail silent]' thunderbird")
    hl.exec_cmd("sleep 3 && obsidian")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
  end)
''

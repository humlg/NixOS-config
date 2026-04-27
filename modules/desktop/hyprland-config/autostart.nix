{ ... }:
''
  # ── Autostart ───────────────────────────────────────────────────
  exec-once = thunar --daemon
  exec-once = ags run
  exec-once = awww-daemon
  exec-once = sleep 1 && waypaper --restore
  exec-once = nm-applet --indicator & blueman-applet &
  exec-once = kwalletd6
  exec-once = sleep 3 && hyprctl dispatch exec "[workspace special:mail silent]" thunderbird
  exec-once = sleep 3 && obsidian
  exec-once = albert
  exec-once = wl-paste --type text  --watch cliphist store
  exec-once = wl-paste --type image --watch cliphist store
''

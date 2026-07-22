{ cfg, reloadDesktop, ... }:
''
  # ── Keybinds ────────────────────────────────────────────────────
  $mainMod = SUPER

  # Lid switch → lock + sleep (cfg.lidSwitchCmd, per-host; default suspend)
  bindl = , switch:on:Lid Switch, exec, $lockScreen & ${cfg.lidSwitchCmd}

  # Core
  bind = $mainMod,       Q, exec,          $terminal
  bind = SUPER SHIFT, 201, exec,		 $menu
  bind = $mainMod,       C, killactive
  bind = $mainMod SHIFT, M, exec,          uwsm stop
  bind = $mainMod SHIFT, R, exec,          ${reloadDesktop}/bin/reload-desktop
  bind = $mainMod,       E, exec,          $fileManager
  bind = $mainMod,       O, togglefloating
  bind = $mainMod,       I, fullscreen
  bind = $mainMod,       R, exec,          $menu
  bind = $mainMod,       P, pseudo
  bind = $mainMod,       J, layoutmsg,    togglesplit
  bind = $mainMod,       F, exec,          $webBrowser
  bind = $mainMod SHIFT, F, exec,          $webBrowser --private-window
  bind = $mainMod,       L, exec,          $lockScreen
  bind = $mainMod,       W, exec,          waypaper
  bind = $mainMod,       N, exec,          swaync-client -R && swaync-client -t
  bind = ALT, TAB,	workspace,	previous

  # Clipboard (cliphist + rofi)
  bind = $mainMod,       V, exec, cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy
  bind = $mainMod SHIFT, V, exec, cliphist wipe

  # Focus
  bind = $mainMod, left,  movefocus, l
  bind = $mainMod, right, movefocus, r
  bind = $mainMod, up,    movefocus, u
  bind = $mainMod, down,  movefocus, d

  # Workspaces 1-10
  bindl = $mainMod, code:10, workspace, 1
  bindl = $mainMod, code:11, workspace, 2
  bindl = $mainMod, code:12, workspace, 3
  bindl = $mainMod, code:13, workspace, 4
  bindl = $mainMod, code:14, workspace, 5
  bindl = $mainMod, code:15, workspace, 6
  bindl = $mainMod, code:16, workspace, 7
  bindl = $mainMod, code:17, workspace, 8
  bindl = $mainMod, code:18, workspace, 9
  bindl = $mainMod, code:19, workspace, 10

  # Workspaces 11-20 (Alt layer)
  bindl = $mainMod ALT, code:10, workspace, 11
  bindl = $mainMod ALT, code:11, workspace, 12
  bindl = $mainMod ALT, code:12, workspace, 13
  bindl = $mainMod ALT, code:13, workspace, 14
  bindl = $mainMod ALT, code:14, workspace, 15
  bindl = $mainMod ALT, code:15, workspace, 16
  bindl = $mainMod ALT, code:16, workspace, 17
  bindl = $mainMod ALT, code:17, workspace, 18
  bindl = $mainMod ALT, code:18, workspace, 19
  bindl = $mainMod ALT, code:19, workspace, 20

  # Relative workspace navigation (- / =)
  bindl = $mainMod, code:20, workspace, e-1
  bindl = $mainMod, code:21, workspace, e+1

  # Move window to workspace 1-10
  bind = $mainMod SHIFT, code:10, movetoworkspace, 1
  bind = $mainMod SHIFT, code:11, movetoworkspace, 2
  bind = $mainMod SHIFT, code:12, movetoworkspace, 3
  bind = $mainMod SHIFT, code:13, movetoworkspace, 4
  bind = $mainMod SHIFT, code:14, movetoworkspace, 5
  bind = $mainMod SHIFT, code:15, movetoworkspace, 6
  bind = $mainMod SHIFT, code:16, movetoworkspace, 7
  bind = $mainMod SHIFT, code:17, movetoworkspace, 8
  bind = $mainMod SHIFT, code:18, movetoworkspace, 9
  bind = $mainMod SHIFT, code:19, movetoworkspace, 10

  # Move window to workspace 11-20 (Alt layer)
  bind = $mainMod SHIFT ALT, code:10, movetoworkspace, 11
  bind = $mainMod SHIFT ALT, code:11, movetoworkspace, 12
  bind = $mainMod SHIFT ALT, code:12, movetoworkspace, 13
  bind = $mainMod SHIFT ALT, code:13, movetoworkspace, 14
  bind = $mainMod SHIFT ALT, code:14, movetoworkspace, 15
  bind = $mainMod SHIFT ALT, code:15, movetoworkspace, 16
  bind = $mainMod SHIFT ALT, code:16, movetoworkspace, 17
  bind = $mainMod SHIFT ALT, code:17, movetoworkspace, 18
  bind = $mainMod SHIFT ALT, code:18, movetoworkspace, 19
  bind = $mainMod SHIFT ALT, code:19, movetoworkspace, 20

  # Move window between monitors
  bind = $mainMod SHIFT, left,  movewindow, l
  bind = $mainMod SHIFT, right, movewindow, r
  bind = $mainMod SHIFT, up,    movewindow, u
  bind = $mainMod SHIFT, down,  movewindow, d

  # Move workspace to monitor
  bind = $mainMod CTRL SHIFT, left,  movecurrentworkspacetomonitor, l
  bind = $mainMod CTRL SHIFT, right, movecurrentworkspacetomonitor, r

  # Special workspaces
  bind = $mainMod,       S, togglespecialworkspace, notes
  bind = $mainMod SHIFT, S, movetoworkspace,        special:notes
  bind = $mainMod,       X, togglespecialworkspace, dashboard
  bind = $mainMod SHIFT, X, movetoworkspace,        special:dashboard
  bind = $mainMod,       T, togglespecialworkspace, mail
  bind = $mainMod SHIFT, T, movetoworkspace,        special:mail

  # Scroll / Ctrl+arrow workspace navigation
  bind = $mainMod, mouse_down, workspace, e+1
  bind = $mainMod, mouse_up,   workspace, e-1
  bind = $mainMod CTRL, right, workspace, +1
  bind = $mainMod CTRL, left,  workspace, -1

  # Mouse move/resize
  bindm = $mainMod, mouse:272, movewindow
  bindm = $mainMod, mouse:273, resizewindow

  # Media / brightness / volume
  bindel = , XF86AudioRaiseVolume,  exec, wpctl set-volume --limit 1.5 @DEFAULT_AUDIO_SINK@   5%+
  bindel = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@   5%-
  bindel = , XF86AudioMute,         exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@   toggle
  bindel = , XF86AudioMicMute,      exec, wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle
  bindel = , XF86MonBrightnessUp,   exec, brightnessctl -e set 5%+
  bindel = , XF86MonBrightnessDown, exec, brightnessctl -e set 5%-
  bindel = , XF86Calculator,        exec, gnome-calculator
  bindl  = , XF86AudioNext,         exec, playerctl next
  bindl  = , XF86AudioPause,        exec, playerctl play-pause
  bindl  = , XF86AudioPlay,         exec, playerctl play-pause
  bindl  = , XF86AudioPrev,         exec, playerctl previous

  # Screenshot (region)
  bind = , PRINT, exec, hyprshot -m region
''

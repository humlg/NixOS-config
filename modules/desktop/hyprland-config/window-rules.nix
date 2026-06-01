{ ... }:
''
  # ── Window rules ────────────────────────────────────────────────
  windowrule = workspace special:mail silent,  match:initial_class ^(thunderbird)$
  # Electron 41 reports Wayland app_id as "electron" — match on title instead
  windowrule = workspace special:notes silent, match:class ^electron$, match:initial_title Obsidian

  windowrule = match:initial_title ^(Albert)$, decorate off, no_shadow on, border_size 0, rounding 0, no_blur on

  windowrule = match:title File Operation Progress,   float on, center on
  windowrule = match:initial_title ^Write:.*,         float on, center on
  windowrule = match:initial_title Calendar Reminders, float on, center on
  windowrule = match:title ^Extension:.*,             float on, center on
  windowrule = match:initial_class org.gnome.Calculator, float on, center on
  windowrule = match:initial_class Todoist, float on, center on
  windowrule = match:initial_class mpv, float on, center on, size 1155 650
''

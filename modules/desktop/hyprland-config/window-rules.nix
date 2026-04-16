{ ... }:
''
  # ── Window rules ────────────────────────────────────────────────
  windowrule = workspace special:mail silent,  match:initial_class ^(thunderbird)$
  windowrule = workspace special:notes silent, match:initial_class ^(obsidian)$

  windowrule = match:initial_class ^(albert)$, noborder on, noshadow on, noanim on, norounding on

  windowrule = match:title File Operation Progress,   float on, center on
  windowrule = match:initial_title ^Write:.*,         float on, center on
  windowrule = match:initial_title Calendar Reminders, float on, center on
  windowrule = match:title ^Extension:.*,             float on, center on
  windowrule = match:initial_class org.gnome.Calculator, float on, center on
  windowrule = match:initial_class Todoist, float on, center on
''

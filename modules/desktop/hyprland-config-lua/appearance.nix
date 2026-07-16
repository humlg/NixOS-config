{ ... }:
''
  -- ── Appearance ──────────────────────────────────────────────────
  -- wc (wallust colors) is loaded before this fragment by the main config.
  hl.config({
    general = {
      gaps_in          = 1,
      gaps_out         = 0,
      border_size      = 2,
      col = {
        active_border   = "rgba(" .. wc.color12:lower() .. "ff)",
        inactive_border = "rgba(595959aa)",
      },
      resize_on_border     = true,
      hover_icon_on_border = true,
      allow_tearing        = false,
      layout               = "dwindle",
    },
    decoration = {
      rounding         = 10,
      active_opacity   = 1,
      inactive_opacity = 1,
      shadow = {
        enabled      = true,
        range        = 4,
        render_power = 3,
        color        = "rgba(1a1a1aee)",
      },
      blur = {
        enabled  = true,
        size     = 5,
        passes   = 2,
        vibrancy = 0.1696,
      },
    },
    animations = {
      enabled = true,
    },
  })

  hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
  hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
  hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
  hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
  hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

  hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
  hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
  hl.animation({ leaf = "borderangle",   enabled = false })
  hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
  hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
  hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
  hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
  hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
  hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
  hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
  hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
  hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
  hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
  hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
  hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
  hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
  hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

  -- swaync blur
  -- swaync's actual gtk-layer-shell namespaces are "swaync-notification-window"
  -- and "swaync-control-center" (not "swaync" — that never matched, so blur
  -- was never applied).
  hl.layer_rule({
    match        = { namespace = "^swaync-" },
    blur         = true,
    ignore_alpha = 0.2,
    dim_around   = false,
  })

  -- anyrun blur (box.main background is semi-transparent, see anyrun.nix)
  hl.layer_rule({
    match        = { namespace = "^anyrun$" },
    blur         = true,
    ignore_alpha = 0.2,
    dim_around   = false,
  })
''

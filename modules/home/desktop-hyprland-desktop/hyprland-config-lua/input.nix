{ cfg, ... }:
let
  # Scrolling: horizontal swipe drags the strip (2× finger speed) and snaps to a column on release;
  # vertical switches workspaces. Built-in "move" drags the window instead — docs/architecture.md.
  gestures = if cfg.layout == "scrolling" then ''
  local stripDrag = { scale = 2.0, snap = 0.25, flick = 25, carry = 0, total = 0, velocity = 0, origin = 0 }

  -- Distinct left edges of the active workspace's tiled columns (target positions, not animated).
  local function stripEdges()
    local ws, edges, seen = hl.get_active_workspace(), {}, {}
    if not ws then return edges end
    for _, w in ipairs(hl.get_windows()) do
      if w.workspace and w.workspace.id == ws.id and not w.floating and not seen[w.at.x] then
        seen[w.at.x] = true
        edges[#edges + 1] = w.at.x
      end
    end
    table.sort(edges)
    return edges
  end

  local function stripMove(px)
    if px ~= 0 then hl.dispatch(hl.dsp.layout("move " .. px)) end
  end

  hl.gesture({ fingers = 3, direction = "horizontal", action = {
    start = function()
      -- Snap anchor: the column edge nearest the monitor's usable left edge.
      local m = hl.get_active_monitor()
      local left = m and (m.position.x + m.reserved.left) or 0
      local best
      for _, x in ipairs(stripEdges()) do
        if not best or math.abs(x - left) < math.abs(best - left) then best = x end
      end
      stripDrag.origin = best or left
      stripDrag.carry, stripDrag.total, stripDrag.velocity = 0, 0, 0
    end,
    update = function(e)
      local dx = e.delta.x * stripDrag.scale + stripDrag.carry
      local px = dx >= 0 and math.floor(dx) or math.ceil(dx)
      stripDrag.carry = dx - px
      stripDrag.total = stripDrag.total + px
      stripDrag.velocity = stripDrag.velocity * 0.5 + e.delta.x * 0.5
      stripMove(px)
    end,
    finish = function(e)
      local o, lo, hi = stripDrag.origin
      for _, x in ipairs(stripEdges()) do
        if x <= o then lo = x elseif not hi then hi = x end
      end
      local target
      if not lo or not hi then
        target = lo or hi
      else
        local frac, v = (o - lo) / (hi - lo), stripDrag.velocity
        if e.cancelled then                 target = frac < 0.5 and lo or hi
        elseif v < -stripDrag.flick then    target = hi
        elseif v >  stripDrag.flick then    target = lo
        elseif stripDrag.total < 0 then     target = frac > stripDrag.snap and hi or lo
        else                                target = frac < 1 - stripDrag.snap and lo or hi
        end
      end
      if target then stripMove(math.floor(o - target + 0.5)) end
    end,
  } })
  hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
'' else ''
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace"  })
  hl.gesture({ fingers = 3, direction = "vertical",   action = "fullscreen" })
'';
in
''
  -- ── Input ───────────────────────────────────────────────────────
  hl.config({
    input = {
      kb_layout          = "cz,us",
      kb_options         = "grp:win_space_toggle",
      numlock_by_default = true,
      follow_mouse       = 1,
      sensitivity        = -0.5,
      accel_profile      = "flat",
      touchpad = {
        natural_scroll = true,
        scroll_factor  = 0.50,
      },
    },
    gestures = {
      workspace_swipe_distance = 200,
      workspace_swipe_forever  = false,
      workspace_swipe_use_r    = true,
    },
  })

  -- hl.gesture() is the Lua equivalent of "gesture = ..." repeated keyword
${gestures}
  -- Per-device overrides
  hl.device({ name = "aet-ms480bbt1-mouse",            sensitivity = -0.5 })
  hl.device({ name = "syna3109:00-06cb:cea3-touchpad", sensitivity = 0    })
  hl.device({ name = "elan06fa:00-04f3:3293-touchpad", sensitivity = 0    })
''

{ cfg, ... }:
let
  # Scrolling: horizontal swipe drags the strip (2× finger speed) and snaps to a column on release;
  # vertical switches workspaces. Built-in "move" drags the window instead — docs/architecture.md.
  gestures = if cfg.layout == "scrolling" then ''
  local stripDrag = { scale = 2.0, snap = 0.25, flick = 25, total = 0, velocity = 0, first0 = 0, lo = 0, hi = 0 }

  -- Active workspace's strip geometry from target (not animated) positions. left/right are the
  -- screen's usable edges where a snapped column sits; first/last are the strip's outer edges.
  local function stripGeometry()
    local ws, m = hl.get_active_workspace(), hl.get_active_monitor()
    if not ws or not m then return nil end
    local border = hl.get_config("general.border_size") or 0
    local gaps = hl.get_config("general.gaps_out")
    local gl = type(gaps) == "table" and gaps.left or 0
    local gr = type(gaps) == "table" and gaps.right or 0
    local g = { edges = {},
      left  = m.position.x + m.reserved.left + border + gl,
      right = m.position.x + m.size.width / m.scale - m.reserved.right - border - gr }
    for _, w in ipairs(hl.get_windows()) do
      if w.workspace and w.workspace.id == ws.id and not w.floating then
        g.edges[#g.edges + 1] = w.at.x
        if not g.first or w.at.x < g.first then g.first = w.at.x end
        if not g.last or w.at.x + w.size.x > g.last then g.last = w.at.x + w.size.x end
      end
    end
    if not g.first then return nil end
    g.maxShift = g.left - g.first                          -- strip start reaches the left edge
    g.minShift = math.min(g.right - g.last, g.maxShift)    -- strip end reaches the right edge
    return g
  end

  -- Rest positions as shifts (px) from where the strip is now: each column edge aligned to the
  -- left edge, clamped to the strip's travel (so a short strip's end is a stop too), plus both ends.
  local function stripStops()
    local g = stripGeometry()
    if not g then return {}, nil end
    local stops = { g.minShift, g.maxShift }
    for _, x in ipairs(g.edges) do
      stops[#stops + 1] = math.max(g.minShift, math.min(g.maxShift, g.left - x))
    end
    table.sort(stops)
    return stops, g
  end

  local function stripMove(px)
    if px ~= 0 then hl.dispatch(hl.dsp.layout("move " .. px)) end
  end

  hl.gesture({ fingers = 3, direction = "horizontal", action = {
    start = function()
      local g = stripGeometry()
      stripDrag.total, stripDrag.velocity = 0, 0
      stripDrag.first0 = g and g.first or 0
      stripDrag.lo, stripDrag.hi = g and g.minShift or 0, g and g.maxShift or 0
    end,
    update = function(e)
      -- Track the intended offset and send the difference from the actual one: the layout pulls
      -- positions within ~250px of the strip start back to it, swallowing small moves — see docs.
      stripDrag.total = math.max(stripDrag.lo, math.min(stripDrag.hi,
        stripDrag.total + e.delta.x * stripDrag.scale))
      stripDrag.velocity = stripDrag.velocity * 0.5 + e.delta.x * 0.5
      local g = stripGeometry()
      if g then stripMove(math.floor(stripDrag.total - (g.first - stripDrag.first0) + 0.5)) end
    end,
    finish = function(e)
      -- Decide from the intended position (off = intended minus actual, from swallowed moves),
      -- then move the actual strip onto the chosen stop. back/fwd = nearest stop behind/ahead.
      local stops, g = stripStops()
      if not g then return end
      local off = stripDrag.total - (g.first - stripDrag.first0)
      local back, fwd, here
      for _, c in ipairs(stops) do
        local d = c - off
        if math.abs(d) <= 3 then here = c
        elseif d > 0 and (not back or d < back - off) then back = c
        elseif d < 0 and (not fwd or d > fwd - off) then fwd = c end
      end
      local target = here
      if not target then
        if not back or not fwd then
          target = back or fwd
        else
          local db, df, v = back - off, fwd - off, stripDrag.velocity
          local gap = db - df
          if e.cancelled then                 target = db < -df and back or fwd
          elseif v < -stripDrag.flick then    target = fwd
          elseif v >  stripDrag.flick then    target = back
          elseif stripDrag.total < 0 then     target = db / gap > stripDrag.snap and fwd or back
          else                                target = -df / gap > stripDrag.snap and back or fwd
          end
        end
      end
      if target then stripMove(math.floor(target + 0.5)) end
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

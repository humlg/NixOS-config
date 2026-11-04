{ cfg, ... }:
let
  # Scrolling: horizontal swipe drags the strip (2× finger speed) and snaps to a column on release;
  # vertical switches workspaces. Built-in "move" drags the window instead — docs/architecture.md.
  gestures = if cfg.layout == "scrolling" then ''
  local stripDrag = { scale = 2.0, snap = 0.25, flick = 25, carry = 0, total = 0, velocity = 0 }

  -- Rest positions for the active workspace's strip, as shifts (px) relative to where it is now:
  -- every column edge aligned to the screen's left edge, clamped to how far the strip can actually
  -- travel (so a short strip's end position is a stop too). Uses target positions, not animated ones.
  local function stripStops()
    local ws, m = hl.get_active_workspace(), hl.get_active_monitor()
    if not ws or not m then return {} end
    local border = hl.get_config("general.border_size") or 0
    local gaps = hl.get_config("general.gaps_out")
    local gl = type(gaps) == "table" and gaps.left or 0
    local gr = type(gaps) == "table" and gaps.right or 0
    local left  = m.position.x + m.reserved.left + border + gl
    local right = m.position.x + m.size.width / m.scale - m.reserved.right - border - gr
    local edges, first, last = {}, nil, nil
    for _, w in ipairs(hl.get_windows()) do
      if w.workspace and w.workspace.id == ws.id and not w.floating then
        edges[#edges + 1] = w.at.x
        if not first or w.at.x < first then first = w.at.x end
        if not last or w.at.x + w.size.x > last then last = w.at.x + w.size.x end
      end
    end
    if not first then return {} end
    local maxShift = left - first                       -- strip start reaches the left edge
    local minShift = math.min(right - last, maxShift)   -- strip end reaches the right edge
    local stops = {}
    for _, x in ipairs(edges) do
      stops[#stops + 1] = math.max(minShift, math.min(maxShift, left - x))
    end
    stops[#stops + 1] = minShift
    stops[#stops + 1] = maxShift
    table.sort(stops)
    return stops
  end

  local function stripMove(px)
    if px ~= 0 then hl.dispatch(hl.dsp.layout("move " .. px)) end
  end

  hl.gesture({ fingers = 3, direction = "horizontal", action = {
    start = function()
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
      -- back = nearest stop behind (shift >= 0), fwd = nearest stop ahead (shift <= 0); 3px tolerance.
      local back, fwd
      for _, c in ipairs(stripStops()) do
        if math.abs(c) <= 3 then return end              -- already resting on a stop
        if c > 0 and (not back or c < back) then back = c end
        if c < 0 and (not fwd or c > fwd) then fwd = c end
      end
      local target
      if not back or not fwd then
        target = back or fwd
      else
        local gap, v = back - fwd, stripDrag.velocity
        if e.cancelled then                 target = back < -fwd and back or fwd
        elseif v < -stripDrag.flick then    target = fwd
        elseif v >  stripDrag.flick then    target = back
        elseif stripDrag.total < 0 then     target = back / gap > stripDrag.snap and fwd or back
        else                                target = -fwd / gap > stripDrag.snap and back or fwd
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

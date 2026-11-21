-- =============================================================================
--  VELA FLEXIBLE TILING ENGINE — Hyprland 0.57.2 Native Lua
--  Supports Dwindle, Master, and Scrolling layouts seamlessly:
--    • Exact split presets: 50/50, 20/80, 30/70, 70/30, 80/20
--    • Instant 2-task Side-by-Side arrangement
--    • Smooth ratio nudging, pane swapping, orientation toggle & live layout switch
-- =============================================================================

local M = {}

M.last_ratio = 50

local CYCLE_RATIOS   = { 50, 20, 80, 30, 70 }
local ORDERED_RATIOS = { 20, 30, 50, 70, 80 }
local LAYOUT_ORDER   = { "dwindle", "scrolling", "master" }

local LAYOUT_LABELS = {
    dwindle   = "Dwindle · Chia nhánh",
    scrolling = "Scrolling · Cột ngang",
    master    = "Master · Ngăn chính",
}

local function win_xy(w)
    if not w or not w.at then return 0, 0 end
    return w.at.x or 0, w.at.y or 0
end

function M.get_layout()
    local ok, ws = pcall(hl.get_active_workspace)
    if ok and ws and ws.tiled_layout and ws.tiled_layout ~= "" then
        return ws.tiled_layout
    end
    local ok2, cfg = pcall(hl.get_config, "general.layout")
    if ok2 and type(cfg) == "string" and cfg ~= "" then
        return cfg
    end
    return "dwindle"
end

local function get_tiled_windows()
    local ok, ws = pcall(hl.get_active_workspace)
    if not ok or not ws then return {} end
    local ok2, wins = pcall(function() return ws:get_windows() end)
    if not ok2 or not wins then return {} end

    local tiled = {}
    for _, w in ipairs(wins) do
        if w and w.mapped and not w.floating and not w.hidden then
            table.insert(tiled, w)
        end
    end

    table.sort(tiled, function(a, b)
        local ax, ay = win_xy(a)
        local bx, by = win_xy(b)
        if math.abs(ax - bx) > 24 then
            return ax < bx
        end
        return ay < by
    end)

    return tiled
end

local function dispatch_layout(msg)
    pcall(function()
        hl.dispatch(hl.dsp.layout(msg))
    end)
end

local function notify_ui(label, pct, mode)
    local safe_label = tostring(label or ""):gsub("'", "")
    local safe_pct   = math.max(0, math.min(100, math.floor(tonumber(pct) or 50)))
    local safe_mode  = tostring(mode or M.get_layout()):gsub("[^a-z]", "")
    hl.exec_cmd(string.format(
        "/home/cuongacoustic/.local/bin/qs -c vela ipc call layout notify '%s' %d '%s' 2>/dev/null || true",
        safe_label, safe_pct, safe_mode
    ))
end

-- Set exact Left / Right (or Master / Stack) split ratio in percentage (e.g. 50, 20, 30, 70, 80)
function M.set_ratio(left_pct)
    local pct = math.max(15, math.min(85, math.floor(tonumber(left_pct) or 50)))
    local frac = pct / 100.0
    local right_pct = 100 - pct
    local layout = M.get_layout()

    if layout == "dwindle" then
        -- Dwindle splitratio is [0.1..1.9] where first child gets splitratio / 2
        dispatch_layout(string.format("splitratio exact %.2f", frac * 2.0))
    elseif layout == "master" then
        dispatch_layout(string.format("mfact exact %.2f", frac))
    elseif layout == "scrolling" then
        local wins = get_tiled_windows()
        local act = hl.get_active_window()
        if #wins >= 2 then
            local idx = 1
            if act then
                for i, w in ipairs(wins) do
                    if w.address == act.address then
                        idx = i
                        break
                    end
                end
            end
            local left_w, right_w
            if #wins == 2 then
                left_w, right_w = wins[1], wins[2]
            elseif idx < #wins then
                left_w, right_w = wins[idx], wins[idx + 1]
            else
                left_w, right_w = wins[idx - 1], wins[idx]
            end

            pcall(function() hl.dispatch(hl.dsp.focus({ window = left_w })) end)
            dispatch_layout(string.format("colresize %.2f", frac))
            pcall(function() hl.dispatch(hl.dsp.focus({ window = right_w })) end)
            dispatch_layout(string.format("colresize %.2f", 1.0 - frac))
            if act then
                pcall(function() hl.dispatch(hl.dsp.focus({ window = act })) end)
            end
            dispatch_layout("fit visible")
        else
            dispatch_layout(string.format("colresize %.2f", frac))
        end
    end

    M.last_ratio = pct
    notify_ui(string.format("Tỷ lệ %d / %d", pct, right_pct), pct, layout)
end

-- Cycle through common ratios: 50/50 -> 20/80 -> 80/20 -> 30/70 -> 70/30
function M.cycle_ratio()
    local next_pct = CYCLE_RATIOS[1]
    for i, r in ipairs(CYCLE_RATIOS) do
        if r == M.last_ratio then
            next_pct = CYCLE_RATIOS[(i % #CYCLE_RATIOS) + 1]
            break
        end
    end
    M.set_ratio(next_pct)
end

-- Step along ordered ratio presets (dir = -1 shrinks left pane, +1 grows left pane)
function M.step_preset(dir)
    local idx = 3 -- default 50
    for i, r in ipairs(ORDERED_RATIOS) do
        if r == M.last_ratio then
            idx = i
            break
        end
    end
    local next_idx = math.max(1, math.min(#ORDERED_RATIOS, idx + (dir or 1)))
    M.set_ratio(ORDERED_RATIOS[next_idx])
end

-- Smoothly nudge active split ratio by +/- delta_pct (e.g. -5 or +5)
function M.nudge_ratio(delta_pct)
    local d = tonumber(delta_pct) or 5
    local layout = M.get_layout()
    if layout == "dwindle" then
        local step = (d / 100.0) * 2.0
        local sign = step >= 0 and "+" or ""
        dispatch_layout(string.format("splitratio %s%.2f", sign, step))
    elseif layout == "master" then
        local step = d / 100.0
        local sign = step >= 0 and "+" or ""
        dispatch_layout(string.format("mfact %s%.2f", sign, step))
    elseif layout == "scrolling" then
        local step = d / 100.0
        local sign = step >= 0 and "+" or ""
        dispatch_layout(string.format("colresize %s%.2f", sign, step))
    end
    M.last_ratio = math.max(15, math.min(85, (M.last_ratio or 50) + d))
end

-- Ensure 2 tasks are positioned cleanly side-by-side (left & right), optionally applying a ratio
function M.side_by_side(ratio_pct)
    local layout = M.get_layout()
    local wins = get_tiled_windows()

    if layout == "dwindle" then
        if #wins >= 2 then
            -- Find active window and closest sibling to check if stacked vertically
            local act = hl.get_active_window()
            local w1, w2 = wins[1], wins[2]
            if act then
                for i, w in ipairs(wins) do
                    if w.address == act.address then
                        w1 = w
                        w2 = wins[i + 1] or wins[i - 1]
                        break
                    end
                end
            end
            if w1 and w2 then
                local x1, y1 = win_xy(w1)
                local x2, y2 = win_xy(w2)
                if math.abs(x1 - x2) < 40 and math.abs(y1 - y2) > 40 then
                    dispatch_layout("togglesplit")
                end
            end
        end
        if ratio_pct then
            M.set_ratio(ratio_pct)
        else
            notify_ui("2 Task cạnh nhau (Ngang)", M.last_ratio or 50, layout)
        end
    elseif layout == "master" then
        dispatch_layout("orientationleft")
        if ratio_pct then
            M.set_ratio(ratio_pct)
        else
            notify_ui("2 Task cạnh nhau (Master)", M.last_ratio or 50, layout)
        end
    elseif layout == "scrolling" then
        if #wins >= 2 then
            local x1, y1 = win_xy(wins[1])
            local x2, y2 = win_xy(wins[2])
            if math.abs(x1 - x2) < 40 and math.abs(y1 - y2) > 40 then
                dispatch_layout("promote")
            end
        end
        M.set_ratio(ratio_pct or 50)
    end
end

-- Universal split orientation toggle (works across Dwindle, Master, Scrolling)
function M.toggle_orientation()
    local layout = M.get_layout()
    if layout == "dwindle" then
        dispatch_layout("togglesplit")
        notify_ui("Đổi chia Ngang ↔ Dọc", M.last_ratio or 50, layout)
    elseif layout == "master" then
        dispatch_layout("orientationcycle left top right bottom center")
        notify_ui("Xoay hướng Master", M.last_ratio or 50, layout)
    elseif layout == "scrolling" then
        dispatch_layout("consume_or_expel")
        notify_ui("Gộp / Tách cột Scrolling", M.last_ratio or 50, layout)
    end
end

-- Universal swap 2 panes
function M.swap_panes()
    local layout = M.get_layout()
    if layout == "dwindle" then
        dispatch_layout("swapsplit")
    elseif layout == "master" then
        dispatch_layout("swapwithmaster")
    elseif layout == "scrolling" then
        dispatch_layout("swapcol r")
    end
    notify_ui("Đảo vị trí 2 ngăn", M.last_ratio or 50, layout)
end

-- Universal promote active window to primary / root / own side-by-side column
function M.promote_pane()
    local layout = M.get_layout()
    if layout == "dwindle" then
        dispatch_layout("movetoroot")
        notify_ui("Đưa ra ngăn chính", M.last_ratio or 50, layout)
    elseif layout == "master" then
        dispatch_layout("swapwithmaster")
        notify_ui("Đưa lên ngăn Master", M.last_ratio or 50, layout)
    elseif layout == "scrolling" then
        dispatch_layout("promote")
        notify_ui("Tách thành cột cạnh nhau", M.last_ratio or 50, layout)
    end
end

-- Switch tiling layout mode live & persist via vela-ctl
function M.set_layout(mode)
    if mode ~= "dwindle" and mode ~= "master" and mode ~= "scrolling" then
        return
    end
    hl.config({ general = { layout = mode } })
    hl.exec_cmd(string.format(
        "/home/cuongacoustic/.local/bin/vela-ctl set layout_mode %s >/dev/null 2>&1 || true",
        mode
    ))
    notify_ui(LAYOUT_LABELS[mode] or mode, M.last_ratio or 50, mode)
end

-- Cycle Dwindle -> Scrolling -> Master
function M.cycle_layout()
    local cur = M.get_layout()
    local next_mode = LAYOUT_ORDER[1]
    for i, m in ipairs(LAYOUT_ORDER) do
        if m == cur then
            next_mode = LAYOUT_ORDER[(i % #LAYOUT_ORDER) + 1]
            break
        end
    end
    M.set_layout(next_mode)
end

_G.vela_tiling = M
return M

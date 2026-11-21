-- Vela Keybindings (Ergonomic end-4 inspired + Windows-style App Search + Rice Studio + Flexible Splits)
local mod    = "SUPER"
local tiling = require("tiling")

-- Core Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Q",      hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))

-- Windows-Style Start / App Search Menu, Rice Settings Studio, Wallpaper Randomizer
hl.bind(mod .. " + Space",       hl.dsp.exec_cmd("qs -c vela ipc call launcher toggle"))
hl.bind(mod .. " + R",           hl.dsp.exec_cmd("qs -c vela ipc call launcher toggle"))
hl.bind(mod .. " + A",           hl.dsp.exec_cmd("qs -c vela ipc call launcher toggle"))
hl.bind(mod .. " + ALT + Space", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -theme ~/.config/rofi/vela.rasi"))
hl.bind(mod .. " + I",           hl.dsp.exec_cmd("qs -c vela ipc call settings toggle"))
hl.bind(mod .. " + D",           hl.dsp.exec_cmd("qs -c vela ipc call deck toggle"))
hl.bind(mod .. " + W",           hl.dsp.exec_cmd("qs -c vela ipc call wallpaper toggle"))
hl.bind(mod .. " + SHIFT + W",   hl.dsp.exec_cmd("~/.local/bin/vela-theme --random"))
hl.bind(mod .. " + ALT + W",     hl.dsp.exec_cmd("~/.local/bin/vela-theme --random-all"))
hl.bind(mod .. " + SHIFT + D",   hl.dsp.exec_cmd("~/.local/bin/vela-theme --mode toggle"))
hl.bind(mod .. " + Escape",      hl.dsp.exec_cmd("qs -c vela ipc call power toggle"))
hl.bind(mod .. " + M",           hl.dsp.exec_cmd("qs -c vela ipc call power toggle"))
hl.bind(mod .. " + V",           hl.dsp.exec_cmd("qs -c vela ipc call clipboard toggle"))
hl.bind(mod .. " + slash",       hl.dsp.exec_cmd("qs -c vela ipc call cheatsheet toggle"))
hl.bind(mod .. " + SHIFT + B",   hl.dsp.exec_cmd("qs -c vela ipc call dock studio"))
hl.bind(mod .. " + ALT + B",     hl.dsp.exec_cmd("qs -c vela ipc call dock cycleStyle"))
hl.bind(mod .. " + CTRL + B",    hl.dsp.exec_cmd("qs -c vela ipc call dock toggle"))
hl.bind(mod .. " + ALT + A",     hl.dsp.exec_cmd("qs -c vela ipc call audio cycle"))
hl.bind(mod .. " + L",           hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + ALT + L",     hl.dsp.exec_cmd("~/.local/bin/vela-login-preview"))
hl.bind(mod .. " + G",           hl.dsp.exec_cmd("~/.local/bin/vela-gamemode"))

-- Screenshots & Color Picker
hl.bind("Print",               hl.dsp.exec_cmd("~/.local/bin/vela-shot region"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/vela-shot region"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd("~/.local/bin/vela-shot full"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Window Management
hl.bind(mod .. " + C",             hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.kill())
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mod .. " + T",             hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",             hl.dsp.window.pseudo())
hl.bind(mod .. " + J",             function() tiling.toggle_orientation() end)
hl.bind(mod .. " + SHIFT + J",     function() tiling.swap_panes() end)
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.center())

-- Flexible Task Splits & Layouts (50/50, 20/80, Side-by-Side, Dwindle / Scrolling / Master)
hl.bind(mod .. " + U",             hl.dsp.exec_cmd("qs -c vela ipc call layout toggle"))
hl.bind(mod .. " + Z",             function() tiling.cycle_layout() end)
hl.bind(mod .. " + ALT + 1",       function() tiling.set_ratio(50) end)
hl.bind(mod .. " + ALT + 2",       function() tiling.set_ratio(20) end)
hl.bind(mod .. " + ALT + 3",       function() tiling.set_ratio(30) end)
hl.bind(mod .. " + ALT + 4",       function() tiling.set_ratio(70) end)
hl.bind(mod .. " + ALT + 5",       function() tiling.set_ratio(80) end)
hl.bind(mod .. " + ALT + 0",       function() tiling.cycle_ratio() end)
hl.bind(mod .. " + ALT + H",       function() tiling.side_by_side(50) end)
hl.bind(mod .. " + ALT + Return",  function() tiling.promote_pane() end)
hl.bind(mod .. " + bracketleft",   function() tiling.step_preset(-1) end)
hl.bind(mod .. " + bracketright",  function() tiling.step_preset(1) end)
hl.bind(mod .. " + minus",         function() tiling.nudge_ratio(-5) end, { repeating = true })
hl.bind(mod .. " + equal",         function() tiling.nudge_ratio(5) end,  { repeating = true })

-- Move / Attach Window to Side (Snap 2 Tasks Side-by-Side or Stacked)
hl.bind(mod .. " + ALT + left",    hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + ALT + right",   hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + ALT + up",      hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + ALT + down",    hl.dsp.window.move({ direction = "down" }))

-- Smooth Keyboard Resize (144Hz Spring-Animated)
hl.bind(mod .. " + CTRL + left",   hl.dsp.window.resize({ x = -40, y = 0 }), { repeating = true })
hl.bind(mod .. " + CTRL + right",  hl.dsp.window.resize({ x = 40,  y = 0 }), { repeating = true })
hl.bind(mod .. " + CTRL + up",     hl.dsp.window.resize({ x = 0, y = -40 }), { repeating = true })
hl.bind(mod .. " + CTRL + down",   hl.dsp.window.resize({ x = 0, y = 40  }), { repeating = true })

-- Focus (Arrows & Vim keys)
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))

-- Swap windows
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))

-- Workspaces 1..10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad Special Workspace
hl.bind(mod .. " + S",       hl.dsp.workspace.toggle_special("prism"))
hl.bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:prism" }))

-- Workspace Cycling
hl.bind(mod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + Tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse Drag & Resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Victus Laptop Volume & Brightness Keys (smooth 2% step, Shift = 1% micro-step; Quickshell PipeWire shows OSD in <1ms)
hl.bind("XF86AudioRaiseVolume",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",         hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),                                                 { locked = true, repeating = true })
hl.bind("SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 1%+"), { locked = true, repeating = true })
hl.bind("SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),                                                 { locked = true, repeating = true })
hl.bind("XF86AudioMute",                hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),                                                { locked = true })
hl.bind("XF86AudioMicMute",             hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),                                              { locked = true })
hl.bind("XF86MonBrightnessUp",          hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && qs -c vela ipc call osd brightness"),                       { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",        hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && qs -c vela ipc call osd brightness"),                       { locked = true, repeating = true })

-- Media Controls
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

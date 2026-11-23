-- Vela Window & Layer Rules (Hyprland 0.57.2 Lua API)

-- Frosted Obsidian Glass Layer Rules for Quickshell Vela & Rofi
-- Overlays drive their own silky 144Hz GPU scale/slide/fade inside QML, so layer_rule uses clean fade (no double-popin stutter)
hl.layer_rule({
    name         = "vela-bar-blur",
    match        = { namespace = "^vela-bar$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "slide top",
})

hl.layer_rule({
    name         = "vela-deck-blur",
    match        = { namespace = "^vela-deck$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-osd-blur",
    match        = { namespace = "^vela-osd$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-wall-blur",
    match        = { namespace = "^vela-wall$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-power-blur",
    match        = { namespace = "^vela-power$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-launcher-blur",
    match        = { namespace = "^vela-launcher$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-settings-blur",
    match        = { namespace = "^vela-settings$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-notifs-blur",
    match        = { namespace = "^vela-notifs$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-clipboard-blur",
    match        = { namespace = "^vela-clipboard$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-cheatsheet-blur",
    match        = { namespace = "^vela-cheatsheet$" },
    blur         = true,
    ignore_alpha = 0.15,
    dim_around   = true,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-layout-blur",
    match        = { namespace = "^vela-layout$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-dock-blur",
    match        = { namespace = "^vela-dock$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "vela-dock-studio-blur",
    match        = { namespace = "^vela-dock-studio$" },
    blur         = true,
    ignore_alpha = 0.15,
    animation    = "fade",
})

hl.layer_rule({
    name         = "rofi-glass-blur",
    match        = { namespace = "^rofi$" },
    blur         = true,
    ignore_alpha = 0.20,
    dim_around   = true,
    animation    = "popin 92%",
})

-- Core Window Rules
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Floating Utility & Media Dialogs
local floatingClasses = {
    "org\\.pulseaudio\\.pavucontrol",
    "pavucontrol",
    "blueman-manager",
    "nwg-look",
    "qt6ct",
    "qt5ct",
    "kvantummanager",
    "com\\.gabm\\.satty",
    "org\\.kde\\.polkit-kde-authentication-agent-1",
    "hyprpolkitagent",
}

for i, cls in ipairs(floatingClasses) do
    hl.window_rule({
        name   = "float-util-" .. i,
        match  = { class = "^(" .. cls .. ")$" },
        float  = true,
        center = true,
    })
end

hl.window_rule({
    name   = "float-pip",
    match  = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float  = true,
    pin    = true,
    size   = "640 360",
})

hl.window_rule({
    name   = "float-file-dialogs",
    match  = { title = "^(Open File|Save File|Choose Files|File Operation Progress).*$" },
    float  = true,
    center = true,
})

-- Crisp opaque media / browsers / games
hl.window_rule({
    name    = "opaque-media-browsers",
    match   = { class = "^(firefox|chromium|brave-browser|mpv|vlc|steam_app_.*)$" },
    opacity = "1.0 1.0",
})

-- 0.57: no wobble for games / fullscreen media so input stays pixel-exact
hl.window_rule({
    name       = "no-wobble-games",
    match      = { class = "^(mpv|vlc|steam_app_.*)$" },
    no_wobble  = true,
})

hl.window_rule({
    name      = "no-wobble-fullscreen",
    match     = { fullscreen = true },
    no_wobble = true,
})

-- 0.57: stop terminals triggering AutoHDR (e.g. foot) in fullscreen
hl.window_rule({
    name        = "no-auto-hdr-terminals",
    match       = { class = "^(kitty|foot|alacritty)$" },
    no_auto_hdr = true,
})

-- 0.57: keep private overlays out of portal screen shares (grim screenshots still see them)
hl.layer_rule({
    name  = "vela-private-overlays-no-share",
    match = { namespace = "^vela-(notifs|osd|power|clipboard|cheatsheet)$" },
    no_screen_share = true,
})

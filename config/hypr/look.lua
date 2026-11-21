-- Vela "Nocturne Prism" Look & Feel (144Hz Butter-Smooth Fluid Springs + Obsidian Glass)
local c = require("colors")

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 14,
        border_size = 2,
        col = {
            active_border   = { colors = { c.primary, c.tertiary }, angle = 35 },
            inactive_border = c.outline_variant,
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 18,
        rounding_power   = 2.6,
        active_opacity   = 1.0,
        inactive_opacity = 0.96,
        dim_inactive     = false,

        shadow = {
            enabled      = true,
            range        = 22,
            render_power = 3,
            color        = c.shadow,
            offset       = { 0, 5 },
        },

        -- Tuned for locked 144fps on AMD Radeon 740M iGPU (lush frosted look, ~40% lighter than 4-pass)
        blur = {
            enabled            = true,
            size               = 7,
            passes             = 3,
            new_optimizations  = true,
            ignore_opacity     = true,
            xray               = false,
            noise              = 0.012,
            contrast           = 1.06,
            brightness         = 1.00,
            vibrancy           = 0.24,
            vibrancy_darkness  = 0.08,
            popups             = true,
            popups_ignorealpha = 0.15,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper      = 0,
        disable_hyprland_logo        = true,
        disable_splash_rendering     = true,
        -- Fullscreen-only VRR: keeps desktop animations locked at silky 144Hz!
        vrr                          = 2,
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,
        focus_on_activate            = true,
    },

    debug = {
        vfr = true,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },

    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        repeat_rate  = 35,
        repeat_delay = 250,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
            scroll_factor        = 0.8,
        },
    },
})

-- 3-finger horizontal touchpad swipe for workspaces (144Hz silky)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- =============================================================================
--  144Hz Fluid Curves & Critically-Damped Springs (Zero-Jitter Apple/Impasto Feel)
-- =============================================================================
hl.curve("velaFluid",     { type = "bezier", points = { {0.16, 1.00}, {0.30, 1.00} } })
hl.curve("velaSilk",      { type = "bezier", points = { {0.22, 1.00}, {0.36, 1.00} } })
hl.curve("velaSnappy",    { type = "bezier", points = { {0.08, 0.92}, {0.18, 1.00} } })
hl.curve("velaWorkspace", { type = "bezier", points = { {0.12, 0.96}, {0.22, 1.00} } })
hl.curve("velaOut",       { type = "bezier", points = { {0.16, 1.00}, {0.30, 1.00} } })
hl.curve("velaLinear",    { type = "bezier", points = { {0.00, 0.00}, {1.00, 1.00} } })

-- Critically-damped springs: butter-smooth acceleration & velvet stop (no harsh wobble)
hl.curve("velaSpring",     { type = "spring", mass = 1.0, stiffness = 260, damping = 28 })
hl.curve("velaMoveSpring", { type = "spring", mass = 1.0, stiffness = 200, damping = 25 })

hl.animation({ leaf = "global",           enabled = true, speed = 6.0, bezier = "velaFluid" })
hl.animation({ leaf = "border",           enabled = true, speed = 5.0, bezier = "velaSilk" })
hl.animation({ leaf = "windows",          enabled = true, speed = 4.4, spring = "velaSpring" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.2, spring = "velaSpring",     style = "popin 88%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3.0, bezier = "velaFluid",      style = "popin 90%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4.6, spring = "velaMoveSpring" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3.2, bezier = "velaSilk" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2.8, bezier = "velaSilk" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2.4, bezier = "velaSilk" })
hl.animation({ leaf = "layers",           enabled = true, speed = 3.6, bezier = "velaFluid" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3.4, bezier = "velaFluid",      style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.4, bezier = "velaSilk",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2.8, bezier = "velaFluid" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 2.2, bezier = "velaSilk" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4.2, bezier = "velaWorkspace",  style = "slide" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 4.2, bezier = "velaWorkspace",  style = "slide" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 4.2, bezier = "velaWorkspace",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2, bezier = "velaWorkspace",  style = "slidevert" })

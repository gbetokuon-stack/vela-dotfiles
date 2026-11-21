-- HP Victus 15-fb3xxx Monitor Configuration
-- Internal panel: 15.6" 1920x1080 @ 144Hz on AMD Radeon 740M (eDP-1)
-- vrr = 2 (fullscreen only) keeps desktop animations locked at butter-smooth 144Hz
-- with zero idle refresh-rate drop stutter, while still giving VRR in fullscreen games!
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
    vrr      = 2,
})

-- Auto-configure any external display (e.g., HDMI-A-1 on NVIDIA RTX 4050)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Hybrid AMD Radeon 740M (iGPU) + NVIDIA RTX 4050 Mobile (dGPU) Environment
-- Ensure ~/.local/bin is in Hyprland's PATH so all keybinds & Vela utilities work immediately
hl.env("PATH", "__HOME__/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin")

-- Multi-GPU DRM Device Discovery:
-- AMD Radeon 740M (card2, boot_vga=1) is automatically selected by Aquamarine as primary compositor GPU.
-- Colon-free symlinks are also maintained in ~/.config/hypr/dri/{amd-igpu,nvidia-dgpu}
-- (NOTE: never pass raw /dev/dri/by-path/pci-0000:xx:xx.x-card to AQ_DRM_DEVICES because Aquamarine splits on ':')
hl.env("AQ_DRM_DEVICES", "__HOME__/.config/hypr/dri/amd-igpu:__HOME__/.config/hypr/dri/nvidia-dgpu")

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkit Wayland Backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- XDG Session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Hardware Video Decode (NVIDIA direct backend when using NVDEC)
hl.env("NVD_BACKEND", "direct")

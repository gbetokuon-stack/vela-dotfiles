-- Vela Session Autostart
hl.on("hyprland.start", function()
    -- 1. Export Wayland & Hyprland session variables to systemd/D-Bus and finalize uwsm if active
    hl.exec_cmd("export PATH=\"$HOME/.local/bin:$PATH\"; dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE PATH 2>/dev/null; systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE PATH 2>/dev/null; command -v uwsm >/dev/null 2>&1 && uwsm finalize 2>/dev/null || true")

    -- 2. Polkit authentication agent
    hl.exec_cmd("systemctl --user start hyprpolkitagent 2>/dev/null || /usr/lib/polkit-kde-authentication-agent-1 2>/dev/null || true")

    -- 3. Wallpaper daemon + restore last wallpaper, palette & live tuning
    hl.exec_cmd("__HOME__/.local/bin/awww-daemon")
    hl.exec_cmd("sleep 0.5 && __HOME__/.local/bin/vela-theme --restore")

    -- 4. Vela Quickshell Desktop Shell (owns bar, command deck, OSD, notifications, wallpaper picker, app launcher, rice studio, power menu)
    hl.exec_cmd("pkill -x dunst 2>/dev/null; __HOME__/.local/bin/quickshell -c vela")

    -- 5. Idle manager & Clipboard history
    hl.exec_cmd("__HOME__/.local/bin/hypridle")
    hl.exec_cmd("__HOME__/.local/bin/wl-paste --type text --watch __HOME__/.local/bin/cliphist store")
    hl.exec_cmd("__HOME__/.local/bin/wl-paste --type image --watch __HOME__/.local/bin/cliphist store")
end)

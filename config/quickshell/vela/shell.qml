//@ pragma UseQApplication
import QtQml
import Quickshell
import Quickshell.Io

ShellRoot {
    // Suppress the default white Qt "Quickshell: Config reloaded" toast on theme/color updates
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }
    }

    TopBar {}
    Dock {}
    DockStudio {}
    CommandDeck {}
    OsdOverlay {}
    WallpaperPicker {}
    AppLauncher {}
    VelaSettings {}
    ClipboardOverlay {}
    KeybindCheatsheet {}
    LayoutOverlay {}
    PowerMenu {}
    NotifPopups {}

    IpcHandler {
        target: "deck"
        function toggle(): void { Store.toggleDeck() }
        function open(): void   { Store.closeAllOverlays(); Store.deckOpen = true; Store.unreadNotifs = 0; Store.refreshTelemetry() }
        function close(): void  { Store.deckOpen = false }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Store.toggleWallpaper() }
        function open(): void   { Store.closeAllOverlays(); Store.wallpaperOpen = true; Store.refreshWallpapers() }
        function close(): void  { Store.wallpaperOpen = false }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Store.toggleLauncher() }
        function open(): void   { Store.closeAllOverlays(); Store.launcherOpen = true; Store.refreshApps() }
        function close(): void  { Store.launcherOpen = false }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { Store.toggleSettings() }
        function open(): void   { Store.closeAllOverlays(); Store.settingsOpen = true; Store.refreshTuning(); Store.refreshTelemetry() }
        function close(): void  { Store.settingsOpen = false }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { Store.toggleClipboard() }
        function open(): void   { Store.closeAllOverlays(); Store.clipboardOpen = true; Store.refreshClipboard() }
        function close(): void  { Store.clipboardOpen = false }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { Store.toggleCheatsheet() }
        function open(): void   { Store.closeAllOverlays(); Store.cheatsheetOpen = true; Store.refreshKeybinds() }
        function close(): void  { Store.cheatsheetOpen = false }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Store.togglePower() }
        function close(): void  { Store.powerOpen = false }
    }

    IpcHandler {
        target: "osd"
        function volume(): void     { Store.showOsd("volume") }
        function brightness(): void { Store.showOsd("brightness") }
    }

    IpcHandler {
        target: "audio"
        function cycle(): void { Store.cycleAudioSink() }
    }

    IpcHandler {
        target: "layout"
        function toggle(): void { Store.toggleLayout() }
        function open(): void   { Store.closeAllOverlays(); Store.layoutOpen = true }
        function close(): void  { Store.layoutOpen = false }
        function notify(label: string, pct: int, mode: string): void { Store.showLayoutOsd(label, pct, mode) }
    }

    IpcHandler {
        target: "dock"
        function toggle(): void                { Store.setTuning("dock_enabled", !Store.dockEnabled) }
        function studio(): void                { Store.toggleDockStudio() }
        function cycleStyle(): void            { Store.cycleDockStyle() }
        function setStyle(style: string): void { Store.applyDockPreset(style) }
        function setPosition(pos: string): void { Store.setTuning("dock_position", pos) }
        function setVisibility(mode: string): void { Store.setTuning("dock_visibility", mode) }
    }
}

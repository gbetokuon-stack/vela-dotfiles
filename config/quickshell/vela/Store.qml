pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Singleton {
    id: root

    // UI overlay visibility
    property bool deckOpen: false
    property bool wallpaperOpen: false
    property bool powerOpen: false
    property bool launcherOpen: false
    property bool settingsOpen: false
    property bool clipboardOpen: false
    property bool cheatsheetOpen: false
    property bool layoutOpen: false
    property bool dockStudioOpen: false
    property bool dndEnabled: false
    property int unreadNotifs: 0
    property var notifHistory: []

    // Clipboard & Keybinds state
    property var clipboardItems: []
    property var keybinds: []

    // Live Cava 12-bar spectrum (0..100)
    property var cavaBars: [4, 8, 12, 16, 20, 14, 18, 10, 14, 8, 6, 4]
    property bool cavaRunning: {
        const players = Mpris.players.values
        if (players) {
            for (let i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) return true
            }
        }
        return root.deckOpen && root.audioStreams.length > 0
    }

    // OSD state
    property bool osdVisible: false
    property string osdKind: "volume"
    property int osdValue: 50
    property bool osdMuted: false
    property string osdText: ""

    // Tiling Layout & Split Ratio state
    property string layoutMode: "dwindle"
    property int layoutRatio: 50

    // Telemetry state (HP Victus Ryzen 7 7445HS + RTX 4050)
    property int cpuPct: 0
    property int cpuTemp: 0
    property int memPct: 0
    property real memUsedGb: 0
    property real memTotalGb: 16
    property string gpuState: "D3cold"
    property string gpuDriver: "nvidia"
    property bool nvidiaPkgInstalled: false
    property bool nvidiaModIndexed: false
    property int gpuTemp: 0
    property int gpuUtil: 0
    property string gpuVram: "0G"
    property int batCap: 100
    property string batStatus: "Unknown"
    property real batWatts: 0
    property string profile: "balanced"
    property int brightness: 80
    property int volume: 50
    property bool muted: false
    property string netType: "ethernet"
    property string netName: "Wired"
    property bool btOn: false
    property bool nightLight: false
    property bool gameMode: false
    property string imEngine: ""

    // Wallpaper, Dark/Light Mode & Matugen scheme state
    property var wallpapers: []
    property string currentWallpaper: ""
    property string currentScheme: "scheme-tonal-spot"
    property string currentMode: "dark"

    // App Launcher index
    property var apps: []

    // Live Rice & Hyprland Tuning state (persisted via vela-ctl)
    property bool blurEnabled: true
    property int blurSize: 7
    property int blurPasses: 3
    property int termOpacity: 68
    property int rounding: 18
    property int gapsIn: 6
    property int gapsOut: 14
    property int borderSize: 2
    property bool animEnabled: true
    property string animPreset: "spring"
    property bool vrrEnabled: true
    property int slideshowMins: 0

    // Dock Suite Configuration (6 Presets + Live Tuning, persisted via vela-ctl)
    property bool dockEnabled: true
    property string dockStyle: "prism"          // "prism" | "macos" | "island" | "cyber" | "taskbar" | "minimal"
    property string dockPosition: "bottom"      // "bottom" | "left" | "right"
    property string dockVisibility: "always"    // "always" | "smart" | "autohide"
    property string dockIndicator: "pill"       // "pill" | "dot" | "bar" | "glow" | "ring"
    property int dockIconSize: 44
    property bool dockMagnify: true
    property int dockMagScale: 135
    property int dockOpacity: 78
    property int dockRadius: 22
    property int dockMargin: 10
    property bool dockShowLabels: true
    property bool dockShowRunning: true
    property bool dockShowUtils: true
    property var dockPinned: ["kitty", "firefox", "org.kde.dolphin", "btop", "pavucontrol"]

    readonly property var dockPresets: [
        {
            id: "prism",
            name: "Nocturne Prism",
            badge: "Vela Signature",
            desc: "Kính obsidian nổi với viền ánh sáng prism & pill động",
            defaults: {
                dock_style: "prism", dock_indicator: "pill", dock_icon_size: 44,
                dock_magnify: true, dock_mag_scale: 132, dock_opacity: 78,
                dock_radius: 22, dock_margin: 10, dock_show_utils: true
            }
        },
        {
            id: "macos",
            name: "macOS Liquid",
            badge: "Wave Zoom",
            desc: "Phóng to lượn sóng parabol mượt 144Hz, chấm sáng cổ điển",
            defaults: {
                dock_style: "macos", dock_indicator: "dot", dock_icon_size: 46,
                dock_magnify: true, dock_mag_scale: 152, dock_opacity: 68,
                dock_radius: 24, dock_margin: 8, dock_show_utils: true
            }
        },
        {
            id: "island",
            name: "Dynamic Islands",
            badge: "3 Pods",
            desc: "Tách 3 cụm đảo kính nổi: Launcher · Apps · Media/Tools",
            defaults: {
                dock_style: "island", dock_indicator: "pill", dock_icon_size: 42,
                dock_magnify: true, dock_mag_scale: 128, dock_opacity: 80,
                dock_radius: 24, dock_margin: 12, dock_show_utils: true
            }
        },
        {
            id: "cyber",
            name: "Cyber Neon HUD",
            badge: "Angular",
            desc: "Viền vát góc sắc cạnh, thanh laser neon & nhãn HUD kỹ thuật",
            defaults: {
                dock_style: "cyber", dock_indicator: "bar", dock_icon_size: 42,
                dock_magnify: true, dock_mag_scale: 124, dock_opacity: 88,
                dock_radius: 10, dock_margin: 10, dock_show_utils: true
            }
        },
        {
            id: "taskbar",
            name: "Glass Taskbar",
            badge: "Full Width",
            desc: "Thanh tác vụ tràn cạnh kiểu Win11 hiện đại + Workspace & Clock",
            defaults: {
                dock_style: "taskbar", dock_indicator: "bar", dock_icon_size: 38,
                dock_magnify: false, dock_mag_scale: 118, dock_opacity: 82,
                dock_radius: 0, dock_margin: 0, dock_show_utils: true
            }
        },
        {
            id: "minimal",
            name: "Ultra Minimal",
            badge: "Feather",
            desc: "Siêu gọn tinh tế, nhẹ mắt, chấm nhỏ cho không gian code",
            defaults: {
                dock_style: "minimal", dock_indicator: "dot", dock_icon_size: 36,
                dock_magnify: true, dock_mag_scale: 122, dock_opacity: 62,
                dock_radius: 18, dock_margin: 8, dock_show_utils: false
            }
        },
        {
            id: "aura",
            name: "Material Aura",
            badge: "Glow Pill",
            desc: "Viên thuốc bo tròn cực đại với hào quang Material You 3 bao icon",
            defaults: {
                dock_style: "aura", dock_indicator: "glow", dock_icon_size: 46,
                dock_magnify: true, dock_mag_scale: 138, dock_opacity: 72,
                dock_radius: 32, dock_margin: 12, dock_show_utils: true
            }
        },
        {
            id: "archbar",
            name: "Arch Tiling Strip",
            badge: "Power User",
            desc: "Thanh gọn gàng kèm Workspace & khung viền sáng chuẩn dân Hyprland",
            defaults: {
                dock_style: "archbar", dock_indicator: "ring", dock_icon_size: 38,
                dock_magnify: false, dock_mag_scale: 115, dock_opacity: 84,
                dock_radius: 12, dock_margin: 8, dock_show_utils: true
            }
        }
    ]

    readonly property string homeDir: Quickshell.env("HOME") || "/home/cuongacoustic"

    // Native real-time PipeWire audio sink & per-app stream bindings
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property bool pipewireAudioReady: Pipewire.ready && defaultSink !== null && defaultSink.ready && defaultSink.audio !== null
    readonly property var audioSinks: {
        if (!Pipewire.ready) return []
        const all = Pipewire.nodes.values
        const out = []
        for (let i = 0; i < all.length; i++) {
            const n = all[i]
            if (n && n.audio && n.isSink && !n.isStream) {
                out.push(n)
            }
        }
        out.sort((a, b) => a.id - b.id)
        return out
    }
    readonly property var audioStreams: {
        if (!Pipewire.ready) return []
        const all = Pipewire.nodes.values
        const out = []
        for (let i = 0; i < all.length; i++) {
            const n = all[i]
            if (n && n.audio && n.isStream && !n.isSink) {
                const nm = (n.name || "").toLowerCase()
                if (nm.includes("cava")) continue
                out.push(n)
            }
        }
        out.sort((a, b) => a.id - b.id)
        return out
    }
    readonly property string activeSinkName: sinkDisplayName(defaultSink)
    readonly property string activeSinkIcon: sinkIcon(defaultSink)
    readonly property bool activeSinkIsHeadset: isHeadsetSink(defaultSink)
    property bool _audioInitialized: false
    property int _pendingBrightness: -1

    PwObjectTracker {
        objects: {
            const list = root.audioSinks.concat(root.audioStreams)
            if (root.defaultSink && list.indexOf(root.defaultSink) === -1) {
                list.push(root.defaultSink)
            }
            return list
        }
    }

    onDefaultSinkChanged: {
        _sinkSettleTimer.restart()
        syncFromPipewire(false)
    }

    Connections {
        target: root.defaultSink
        function onReadyChanged() {
            root.syncFromPipewire(false)
        }
    }

    Connections {
        target: root.defaultSink?.audio ?? null
        function onVolumesChanged() {
            root.syncFromPipewire(true)
        }
        function onMutedChanged() {
            root.syncFromPipewire(true)
        }
    }

    Timer {
        id: _sinkSettleTimer
        interval: 400
        running: true
        repeat: false
        onTriggered: {
            root.syncFromPipewire(false)
            root._audioInitialized = true
        }
    }

    Timer {
        id: _brightnessFlushTimer
        interval: 25
        repeat: false
        onTriggered: {
            if (root._pendingBrightness >= 0) {
                const target = root._pendingBrightness
                root._pendingBrightness = -1
                Quickshell.execDetached(["brightnessctl", "set", `${target}%`])
            }
        }
    }

    // Automatic Wallpaper Slideshow Timer
    Timer {
        id: slideshowTimer
        interval: Math.max(1, root.slideshowMins) * 60000
        running: root.slideshowMins > 0
        repeat: true
        onTriggered: root.randomWallpaper()
    }

    // Live Cava Spectrum Process (only runs when media plays or Deck mixer is open)
    Process {
        id: cavaProc
        command: ["bash", "-lc", "~/.local/bin/vela-cava"]
        running: root.cavaRunning
        stdout: SplitParser {
            onRead: line => {
                const raw = line.trim()
                if (!raw) return
                const parts = raw.split(";")
                const bars = []
                for (let i = 0; i < 12; i++) {
                    const v = i < parts.length ? parseInt(parts[i], 10) : 0
                    bars.push(isNaN(v) ? 0 : Math.max(0, Math.min(100, v)))
                }
                root.cavaBars = bars
            }
        }
    }

    function syncFromPipewire(allowOsd) {
        if (!pipewireAudioReady) return
        const rawVol = defaultSink.audio.volume
        if (rawVol === undefined || rawVol === null || isNaN(rawVol) || !isFinite(rawVol)) return
        const nextVol = Math.max(0, Math.min(150, Math.round(rawVol * 100)))
        const nextMuted = Boolean(defaultSink.audio.muted)
        const changed = (nextVol !== root.volume) || (nextMuted !== root.muted)
        root.volume = nextVol
        root.muted = nextMuted
        if (root.osdKind === "volume") {
            root.osdValue = nextVol
            root.osdMuted = nextMuted
        }
        if (allowOsd && changed && root._audioInitialized && !_sinkSettleTimer.running && !root.deckOpen) {
            showOsd("volume")
        }
    }

    // Notification history helpers
    function pushNotification(appName, summary, body, critical) {
        const now = Qt.formatDateTime(new Date(), "HH:mm")
        const entry = {
            id: Date.now() + Math.random(),
            appName: appName || "System",
            summary: summary || "Notification",
            body: body || "",
            critical: Boolean(critical),
            time: now
        }
        const next = [entry].concat(root.notifHistory || [])
        if (next.length > 25) next.length = 25
        root.notifHistory = next
        if (!root.deckOpen) {
            root.unreadNotifs = Math.min(99, root.unreadNotifs + 1)
        }
    }

    function removeHistoryItem(idx) {
        const next = (root.notifHistory || []).slice()
        if (idx >= 0 && idx < next.length) {
            next.splice(idx, 1)
            root.notifHistory = next
        }
    }

    function clearNotifHistory() {
        root.notifHistory = []
        root.unreadNotifs = 0
    }

    function closeAllOverlays() {
        deckOpen = false
        wallpaperOpen = false
        powerOpen = false
        launcherOpen = false
        settingsOpen = false
        clipboardOpen = false
        cheatsheetOpen = false
        layoutOpen = false
        dockStudioOpen = false
    }

    function toggleDeck() {
        const next = !deckOpen
        closeAllOverlays()
        deckOpen = next
        if (next) {
            unreadNotifs = 0
            refreshTelemetry()
        }
    }

    function toggleWallpaper() {
        const next = !wallpaperOpen
        closeAllOverlays()
        wallpaperOpen = next
        if (next) refreshWallpapers()
    }

    function togglePower() {
        const next = !powerOpen
        closeAllOverlays()
        powerOpen = next
    }

    function toggleLauncher() {
        const next = !launcherOpen
        closeAllOverlays()
        launcherOpen = next
        if (next) refreshApps()
    }

    function toggleSettings() {
        const next = !settingsOpen
        closeAllOverlays()
        settingsOpen = next
        if (next) {
            refreshTelemetry()
            refreshTuning()
        }
    }

    function toggleClipboard() {
        const next = !clipboardOpen
        closeAllOverlays()
        clipboardOpen = next
        if (next) refreshClipboard()
    }

    function toggleCheatsheet() {
        const next = !cheatsheetOpen
        closeAllOverlays()
        cheatsheetOpen = next
        if (next) refreshKeybinds()
    }

    function toggleLayout() {
        const next = !layoutOpen
        closeAllOverlays()
        layoutOpen = next
    }

    function toggleDockStudio() {
        const next = !dockStudioOpen
        closeAllOverlays()
        dockStudioOpen = next
        if (next) refreshApps()
    }

    function applyDockPreset(presetId) {
        let preset = null
        for (let i = 0; i < dockPresets.length; i++) {
            if (dockPresets[i].id === presetId) {
                preset = dockPresets[i]
                break
            }
        }
        if (!preset) return
        const d = preset.defaults
        dockEnabled = true
        dockStyle = d.dock_style
        dockIndicator = d.dock_indicator
        dockIconSize = d.dock_icon_size
        dockMagnify = d.dock_magnify
        dockMagScale = d.dock_mag_scale
        dockOpacity = d.dock_opacity
        dockRadius = d.dock_radius
        dockMargin = d.dock_margin
        dockShowUtils = d.dock_show_utils
        const payload = Object.assign({ dock_enabled: true }, d)
        const jsonArg = JSON.stringify(payload).replace(/'/g, "'\\''")
        runCmd(`~/.local/bin/vela-ctl set-multi '${jsonArg}'`)
    }

    function cycleDockStyle() {
        const order = ["prism", "macos", "island", "cyber", "taskbar", "minimal", "aura", "archbar"]
        const idx = order.indexOf(dockStyle)
        const next = order[(idx + 1) % order.length]
        applyDockPreset(next)
        for (let i = 0; i < dockPresets.length; i++) {
            if (dockPresets[i].id === next) {
                osdKind = "layout"
                osdText = `Dock · ${dockPresets[i].name}`
                osdValue = Math.round(((idx + 1) % order.length + 1) / order.length * 100)
                osdMuted = false
                osdVisible = true
                osdHideTimer.restart()
                break
            }
        }
    }

    function togglePinDockApp(appId) {
        if (!appId) return
        const key = String(appId).trim()
        const cur = Array.isArray(dockPinned) ? dockPinned.slice() : []
        const lower = key.toLowerCase()
        const existingIdx = cur.findIndex(x => String(x).toLowerCase() === lower)
        if (existingIdx >= 0) {
            cur.splice(existingIdx, 1)
        } else {
            cur.push(key)
        }
        dockPinned = cur
        const jsonArg = JSON.stringify({ dock_pinned: cur }).replace(/'/g, "'\\''")
        runCmd(`~/.local/bin/vela-ctl set-multi '${jsonArg}'`)
    }

    function isDockAppPinned(appId) {
        if (!appId || !Array.isArray(dockPinned)) return false
        const lower = String(appId).toLowerCase()
        for (let i = 0; i < dockPinned.length; i++) {
            const p = String(dockPinned[i]).toLowerCase()
            if (p === lower || p.endsWith("." + lower) || lower.endsWith("." + p)) return true
        }
        return false
    }

    function resetDock() {
        dockEnabled = true
        dockStyle = "prism"
        dockPosition = "bottom"
        dockVisibility = "always"
        dockIndicator = "pill"
        dockIconSize = 44
        dockMagnify = true
        dockMagScale = 135
        dockOpacity = 78
        dockRadius = 22
        dockMargin = 10
        dockShowLabels = true
        dockShowRunning = true
        dockShowUtils = true
        dockPinned = ["kitty", "firefox", "org.kde.dolphin", "btop", "pavucontrol"]
        runCmd("~/.local/bin/vela-ctl dock-reset")
    }

    function showLayoutOsd(label, pct, mode) {
        if (mode && (mode === "dwindle" || mode === "scrolling" || mode === "master" || mode === "monocle")) {
            layoutMode = mode
        }
        const p = Math.max(0, Math.min(100, Math.round(pct || 50)))
        if (p >= 15 && p <= 85) {
            layoutRatio = p
        }
        osdKind = "layout"
        osdText = label || layoutMode
        osdValue = p
        osdMuted = false
        osdVisible = true
        osdHideTimer.restart()
    }

    function setLayoutMode(mode) {
        layoutMode = mode
        Quickshell.execDetached(["hyprctl", "eval", `vela_tiling.set_layout('${mode}')`])
    }

    function cycleLayoutMode() {
        Quickshell.execDetached(["hyprctl", "eval", "vela_tiling.cycle_layout()"])
    }

    function setSplitRatio(pct) {
        layoutRatio = pct
        Quickshell.execDetached(["hyprctl", "eval", `vela_tiling.set_ratio(${pct})`])
    }

    function cycleSplitRatio() {
        Quickshell.execDetached(["hyprctl", "eval", "vela_tiling.cycle_ratio()"])
    }

    function tilingSideBySide(pct) {
        const p = pct || 50
        layoutRatio = p
        Quickshell.execDetached(["hyprctl", "eval", `vela_tiling.side_by_side(${p})`])
    }

    function tilingAction(fnName) {
        Quickshell.execDetached(["hyprctl", "eval", `vela_tiling.${fnName}()`])
    }

    function showOsd(kind) {
        osdKind = kind
        if (kind === "volume") {
            osdValue = volume
            osdMuted = muted
        } else {
            osdValue = brightness
            osdMuted = false
            refreshTelemetry()
        }
        osdVisible = true
        osdHideTimer.restart()
    }

    function runCmd(cmd) {
        Quickshell.execDetached(["bash", "-lc", "export PATH=\"$HOME/.local/bin:$PATH\"; " + cmd])
    }

    function recordAppLaunch(appId) {
        if (!appId) return
        runCmd(`~/.local/bin/vela-apps --record "${appId}"`)
    }

    function toggleInputMethod() {
        runCmd("fcitx5-remote -t")
        imRefreshDelay.restart()
    }

    function setVolume(pct) {
        const clamped = Math.max(0, Math.min(120, Math.round(pct)))
        volume = clamped
        if (osdKind === "volume") {
            osdValue = clamped
            osdMuted = muted
        }
        if (pipewireAudioReady) {
            const target = clamped / 100.0
            if (Math.abs((defaultSink.audio.volume ?? 0) - target) > 0.001) {
                defaultSink.audio.volume = target
            }
            if (clamped > 0 && defaultSink.audio.muted) {
                muted = false
                defaultSink.audio.muted = false
                if (osdKind === "volume") osdMuted = false
            }
        } else {
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${clamped}%`])
        }
    }

    function adjustVolume(delta) {
        setVolume(volume + delta)
    }

    function toggleMute() {
        const next = !muted
        muted = next
        if (osdKind === "volume") {
            osdValue = volume
            osdMuted = next
        }
        if (pipewireAudioReady) {
            defaultSink.audio.muted = next
        } else {
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        }
    }

    function isHeadsetSink(node) {
        if (!node) return false
        const text = `${node.name || ""} ${node.description || ""} ${node.nickname || ""}`.toLowerCase()
        return text.includes("usb") || text.includes("headphone") || text.includes("headset")
            || text.includes("bunny") || text.includes("gaming") || text.includes("ear")
            || text.includes("airpod") || text.includes("buds") || text.includes("bluez")
    }

    function sinkIcon(node) {
        if (!node) return "󰕾"
        const text = `${node.name || ""} ${node.description || ""} ${node.nickname || ""}`.toLowerCase()
        if (text.includes("bluez") || text.includes("bluetooth")) return "󰂯"
        if (text.includes("hdmi") || text.includes("displayport")) return "󰍹"
        if (isHeadsetSink(node)) return "󰋋"
        return "󰓃"
    }

    function sinkDisplayName(node) {
        if (!node) return "Audio"
        const name = (node.name || "").toLowerCase()
        const desc = (node.description || node.nickname || node.name || "Audio").trim()
        if (name.includes("pci-") && desc.toLowerCase().includes("speaker")) {
            return "Loa Laptop"
        }
        if (name.includes("pci-") && desc.toLowerCase().includes("headphone")) {
            return "Tai nghe 3.5mm"
        }
        return desc
            .replace(/\s+Analog Stereo$/i, "")
            .replace(/\s+Digital Stereo.*$/i, "")
            .replace(/\s+Stereo$/i, "")
            .trim() || desc
    }

    function streamDisplayName(node) {
        if (!node) return "App"
        const props = node.properties || {}
        const app = props["application.name"] || node.nickname || node.description || node.name || "App"
        return String(app).trim()
    }

    function streamIcon(node) {
        const s = streamDisplayName(node).toLowerCase()
        if (s.includes("firefox") || s.includes("zen")) return "󰈹"
        if (s.includes("chrom") || s.includes("brave")) return "󰊯"
        if (s.includes("spotify")) return "󰓇"
        if (s.includes("discord") || s.includes("vesktop")) return "󰙯"
        if (s.includes("mpv") || s.includes("vlc")) return "󰐊"
        if (s.includes("steam") || s.includes("wine") || s.includes("proton")) return "󰓓"
        return "󰎈"
    }

    function sinkSubtitle(node) {
        if (!node) return ""
        const name = (node.name || "").toLowerCase()
        if (name.includes("usb-")) return "USB Audio"
        if (name.includes("bluez")) return "Bluetooth"
        if (name.includes("hdmi")) return "HDMI / DisplayPort"
        const nick = (node.nickname || "").trim()
        if (nick && nick !== sinkDisplayName(node)) return nick
        return "Internal Speaker"
    }

    function sinkVolumePct(node) {
        if (!node || !node.ready || !node.audio) return 0
        const v = node.audio.volume
        if (v === undefined || v === null || isNaN(v) || !isFinite(v)) return 0
        return Math.max(0, Math.min(150, Math.round(v * 100)))
    }

    function isSinkDefault(node) {
        if (!node || !root.defaultSink) return false
        return node.id === root.defaultSink.id
    }

    function setDefaultSink(node) {
        if (!node) return
        Pipewire.preferredDefaultAudioSink = node
        Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
        if (node.name) {
            Quickshell.execDetached([
                "bash", "-c",
                "pactl set-default-sink \"$1\" 2>/dev/null; for id in $(pactl list short sink-inputs 2>/dev/null | awk '{print $1}'); do pactl move-sink-input \"$id\" \"$1\" 2>/dev/null; done",
                "_", String(node.name)
            ])
        }
        if (node.ready && node.audio) {
            root.volume = sinkVolumePct(node)
            root.muted = Boolean(node.audio.muted)
        }
    }

    function cycleAudioSink() {
        const list = root.audioSinks
        if (!list || list.length < 2) return
        let curIdx = -1
        if (root.defaultSink) {
            for (let i = 0; i < list.length; i++) {
                if (list[i].id === root.defaultSink.id) {
                    curIdx = i
                    break
                }
            }
        }
        const next = list[(curIdx + 1) % list.length]
        setDefaultSink(next)
        showOsd("volume")
    }

    function setSinkVolume(node, pct) {
        if (!node) return
        const clamped = Math.max(0, Math.min(120, Math.round(pct)))
        if (node.ready && node.audio) {
            const target = clamped / 100.0
            if (Math.abs((node.audio.volume ?? 0) - target) > 0.001) {
                node.audio.volume = target
            }
            if (clamped > 0 && node.audio.muted) {
                node.audio.muted = false
            }
        } else {
            Quickshell.execDetached(["wpctl", "set-volume", String(node.id), `${clamped}%`])
        }
        if (isSinkDefault(node)) {
            root.volume = clamped
            if (clamped > 0 && root.muted) root.muted = false
            if (root.osdKind === "volume") {
                root.osdValue = clamped
                root.osdMuted = root.muted
            }
        }
    }

    function toggleSinkMute(node) {
        if (!node) return
        if (node.ready && node.audio) {
            const next = !Boolean(node.audio.muted)
            node.audio.muted = next
            if (isSinkDefault(node)) {
                root.muted = next
                if (root.osdKind === "volume") {
                    root.osdValue = root.volume
                    root.osdMuted = next
                }
            }
        } else {
            Quickshell.execDetached(["wpctl", "set-mute", String(node.id), "toggle"])
        }
    }

    function setBrightness(pct) {
        const clamped = Math.max(5, Math.min(100, Math.round(pct)))
        brightness = clamped
        if (osdKind === "brightness") {
            osdValue = clamped
            osdMuted = false
        }
        _pendingBrightness = clamped
        if (!_brightnessFlushTimer.running) {
            _brightnessFlushTimer.start()
        }
    }

    function cycleProfile() {
        const order = ["power-saver", "balanced", "performance"]
        const idx = order.indexOf(profile)
        const next = order[(idx + 1) % order.length]
        setProfile(next)
    }

    function setProfile(p) {
        profile = p
        runCmd(`powerprofilesctl set ${p}`)
    }

    function toggleNightLight() {
        if (nightLight) {
            nightLight = false
            runCmd("pkill -x hyprsunset")
        } else {
            nightLight = true
            runCmd("hyprsunset -t 4200")
        }
    }

    function toggleBluetooth() {
        const target = btOn ? "off" : "on"
        btOn = !btOn
        runCmd(`bluetoothctl power ${target}`)
    }

    function toggleGameMode() {
        gameMode = !gameMode
        runCmd("~/.local/bin/vela-gamemode")
    }

    function applyWallpaper(path) {
        currentWallpaper = path
        runCmd(`~/.local/bin/vela-theme "${path}" --scheme "${currentScheme}" --mode "${currentMode}"`)
    }

    function applyScheme(scheme) {
        currentScheme = scheme
        const wall = currentWallpaper || (wallpapers.length > 0 ? wallpapers[0] : "")
        if (wall) {
            runCmd(`~/.local/bin/vela-theme "${wall}" --scheme "${scheme}" --mode "${currentMode}"`)
        }
    }

    function toggleDarkLight() {
        const next = currentMode === "dark" ? "light" : "dark"
        setDarkLight(next)
    }

    function setDarkLight(mode) {
        currentMode = mode
        runCmd(`~/.local/bin/vela-theme --mode "${mode}"`)
    }

    function randomWallpaper() {
        runCmd("~/.local/bin/vela-theme --random")
        wallRefreshDelay.restart()
    }

    function randomThemeAll() {
        runCmd("~/.local/bin/vela-theme --random-all")
        wallRefreshDelay.restart()
    }

    function setTuning(key, val) {
        if (key === "blur_enabled") blurEnabled = Boolean(val)
        else if (key === "blur_size") blurSize = Number(val)
        else if (key === "blur_passes") blurPasses = Number(val)
        else if (key === "term_opacity") termOpacity = Number(val)
        else if (key === "rounding") rounding = Number(val)
        else if (key === "gaps_in") gapsIn = Number(val)
        else if (key === "gaps_out") gapsOut = Number(val)
        else if (key === "border_size") borderSize = Number(val)
        else if (key === "anim_enabled") animEnabled = Boolean(val)
        else if (key === "anim_preset") animPreset = String(val)
        else if (key === "vrr_enabled") vrrEnabled = Boolean(val)
        else if (key === "slideshow_mins") slideshowMins = Number(val)
        else if (key === "dock_enabled") dockEnabled = Boolean(val)
        else if (key === "dock_style") dockStyle = String(val)
        else if (key === "dock_position") dockPosition = String(val)
        else if (key === "dock_visibility") dockVisibility = String(val)
        else if (key === "dock_indicator") dockIndicator = String(val)
        else if (key === "dock_icon_size") dockIconSize = Number(val)
        else if (key === "dock_magnify") dockMagnify = Boolean(val)
        else if (key === "dock_mag_scale") dockMagScale = Number(val)
        else if (key === "dock_opacity") dockOpacity = Number(val)
        else if (key === "dock_radius") dockRadius = Number(val)
        else if (key === "dock_margin") dockMargin = Number(val)
        else if (key === "dock_show_labels") dockShowLabels = Boolean(val)
        else if (key === "dock_show_running") dockShowRunning = Boolean(val)
        else if (key === "dock_show_utils") dockShowUtils = Boolean(val)
        runCmd(`~/.local/bin/vela-ctl set ${key} ${val}`)
    }

    function resetTuning() {
        runCmd("~/.local/bin/vela-ctl reset")
        tuningRefreshDelay.restart()
    }

    function copyClipboardItem(id) {
        runCmd(`~/.local/bin/vela-clipboard copy "${id}"`)
    }

    function deleteClipboardItem(id) {
        runCmd(`~/.local/bin/vela-clipboard delete "${id}"`)
        clipRefreshDelay.restart()
    }

    function togglePinClipboard(id) {
        runCmd(`~/.local/bin/vela-clipboard pin "${id}"`)
        clipRefreshDelay.restart()
    }

    function clearClipboard() {
        runCmd("~/.local/bin/vela-clipboard clear")
        clipboardItems = []
        clipRefreshDelay.restart()
    }

    function installNvidiaDriver() {
        closeAllOverlays()
        if (nvidiaPkgInstalled) {
            runCmd("kitty --title 'Vela RTX 4050 UKI Activator' -e bash -lc '~/.local/bin/vela-fix-nvidia; echo; read -p \"Xong! Nhấn Enter để đóng...\"'")
        } else {
            runCmd("kitty --title 'Vela NVIDIA RTX 4050 Driver Installer' -e bash -lc '~/setup-victus-drivers-and-rice.sh; echo; read -p \"Done! Press Enter to close...\"'")
        }
    }

    function refreshTelemetry() {
        if (!telemetryProc.running) telemetryProc.running = true
    }

    function refreshWallpapers() {
        if (!wallListProc.running) wallListProc.running = true
    }

    function refreshApps() {
        if (!appsProc.running) appsProc.running = true
    }

    function refreshTuning() {
        if (!tuningProc.running) tuningProc.running = true
    }

    function refreshClipboard() {
        if (!clipProc.running) clipProc.running = true
    }

    function refreshKeybinds() {
        if (!keybindsProc.running) keybindsProc.running = true
    }

    Timer {
        id: osdHideTimer
        interval: 1600
        repeat: false
        onTriggered: root.osdVisible = false
    }

    Timer {
        id: wallRefreshDelay
        interval: 600
        repeat: false
        onTriggered: root.refreshWallpapers()
    }

    Timer {
        id: tuningRefreshDelay
        interval: 300
        repeat: false
        onTriggered: root.refreshTuning()
    }

    Timer {
        id: clipRefreshDelay
        interval: 200
        repeat: false
        onTriggered: root.refreshClipboard()
    }

    Timer {
        id: imRefreshDelay
        interval: 150
        repeat: false
        onTriggered: root.refreshTelemetry()
    }

    Timer {
        interval: 3500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshTelemetry()
    }

    Process {
        id: telemetryProc
        command: [root.homeDir + "/.local/bin/vela-telemetry"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data)
                    root.cpuPct = d.cpu_pct ?? 0
                    root.cpuTemp = d.cpu_temp ?? 0
                    root.memPct = d.mem_pct ?? 0
                    root.memUsedGb = d.mem_used_gb ?? 0
                    root.memTotalGb = d.mem_total_gb ?? 16
                    root.gpuState = d.gpu_state ?? "D3cold"
                    root.gpuDriver = d.gpu_driver ?? "nvidia"
                    root.nvidiaPkgInstalled = d.nvidia_pkg_installed ?? false
                    root.nvidiaModIndexed = d.nvidia_mod_indexed ?? false
                    root.gpuTemp = d.gpu_temp ?? 0
                    root.gpuUtil = d.gpu_util ?? 0
                    root.gpuVram = d.gpu_vram ?? "0G"
                    root.batCap = d.bat_cap ?? 100
                    root.batStatus = d.bat_status ?? "Unknown"
                    root.batWatts = d.bat_watts ?? 0
                    root.profile = d.profile ?? "balanced"
                    root.brightness = d.brightness ?? 80
                    if (!root.pipewireAudioReady) {
                        root.volume = d.volume ?? 50
                        root.muted = d.muted ?? false
                    }
                    root.netType = d.net_type ?? "offline"
                    root.netName = d.net_name ?? "Offline"
                    root.btOn = d.bt_on ?? false
                    root.nightLight = d.night_light ?? false
                    root.gameMode = d.game_mode ?? false
                    root.imEngine = d.im_engine ?? ""
                    if (d.layout_mode) root.layoutMode = d.layout_mode
                    if (root.osdKind === "volume") {
                        root.osdValue = root.volume
                        root.osdMuted = root.muted
                    } else if (root.osdKind === "brightness") {
                        root.osdValue = root.brightness
                        root.osdMuted = false
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: wallListProc
        command: ["bash", "-lc", "python3 -c 'import glob,os,json; d=os.path.expanduser(\"~/Pictures/Wallpapers\"); ws=sorted([p for p in glob.glob(d+\"/*\") if p.lower().endswith((\".jpg\",\".jpeg\",\".png\",\".webp\"))]); cw=open(os.path.expanduser(\"~/.cache/vela/current_wallpaper\")).read().strip() if os.path.exists(os.path.expanduser(\"~/.cache/vela/current_wallpaper\")) else (ws[0] if ws else \"\"); cs=open(os.path.expanduser(\"~/.cache/vela/current_scheme\")).read().strip() if os.path.exists(os.path.expanduser(\"~/.cache/vela/current_scheme\")) else \"scheme-tonal-spot\"; cm=open(os.path.expanduser(\"~/.cache/vela/current_mode\")).read().strip() if os.path.exists(os.path.expanduser(\"~/.cache/vela/current_mode\")) else \"dark\"; print(json.dumps({\"wallpapers\":ws,\"current\":cw,\"scheme\":cs,\"mode\":cm}))'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data)
                    root.wallpapers = d.wallpapers ?? []
                    root.currentWallpaper = d.current ?? ""
                    root.currentScheme = d.scheme ?? "scheme-tonal-spot"
                    root.currentMode = d.mode ?? "dark"
                } catch (e) {}
            }
        }
    }

    Process {
        id: appsProc
        command: ["bash", "-lc", "~/.local/bin/vela-apps"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.apps = JSON.parse(data)
                } catch (e) {}
            }
        }
    }

    Process {
        id: tuningProc
        command: ["bash", "-lc", "~/.local/bin/vela-ctl get"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const c = JSON.parse(data)
                    root.blurEnabled = c.blur_enabled ?? true
                    root.blurSize = c.blur_size ?? 7
                    root.blurPasses = c.blur_passes ?? 3
                    root.termOpacity = c.term_opacity ?? 68
                    root.rounding = c.rounding ?? 18
                    root.gapsIn = c.gaps_in ?? 6
                    root.gapsOut = c.gaps_out ?? 14
                    root.borderSize = c.border_size ?? 2
                    root.animEnabled = c.anim_enabled ?? true
                    root.animPreset = c.anim_preset ?? "spring"
                    root.vrrEnabled = c.vrr_enabled ?? true
                    root.slideshowMins = c.slideshow_mins ?? 0
                    if (c.layout_mode) root.layoutMode = c.layout_mode
                    if (c.dock_enabled !== undefined) root.dockEnabled = Boolean(c.dock_enabled)
                    if (c.dock_style) root.dockStyle = String(c.dock_style)
                    if (c.dock_position) root.dockPosition = String(c.dock_position)
                    if (c.dock_visibility) root.dockVisibility = String(c.dock_visibility)
                    if (c.dock_indicator) root.dockIndicator = String(c.dock_indicator)
                    if (c.dock_icon_size !== undefined) root.dockIconSize = Number(c.dock_icon_size)
                    if (c.dock_magnify !== undefined) root.dockMagnify = Boolean(c.dock_magnify)
                    if (c.dock_mag_scale !== undefined) root.dockMagScale = Number(c.dock_mag_scale)
                    if (c.dock_opacity !== undefined) root.dockOpacity = Number(c.dock_opacity)
                    if (c.dock_radius !== undefined) root.dockRadius = Number(c.dock_radius)
                    if (c.dock_margin !== undefined) root.dockMargin = Number(c.dock_margin)
                    if (c.dock_show_labels !== undefined) root.dockShowLabels = Boolean(c.dock_show_labels)
                    if (c.dock_show_running !== undefined) root.dockShowRunning = Boolean(c.dock_show_running)
                    if (c.dock_show_utils !== undefined) root.dockShowUtils = Boolean(c.dock_show_utils)
                    if (Array.isArray(c.dock_pinned)) root.dockPinned = c.dock_pinned
                } catch (e) {}
            }
        }
    }

    Process {
        id: clipProc
        command: ["bash", "-lc", "~/.local/bin/vela-clipboard list"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.clipboardItems = JSON.parse(data)
                } catch (e) {}
            }
        }
    }

    Process {
        id: keybindsProc
        command: ["bash", "-lc", "~/.local/bin/vela-keybinds"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data)
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: {
        refreshWallpapers()
        refreshApps()
        refreshTuning()
        refreshKeybinds()
    }
}

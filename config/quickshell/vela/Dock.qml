import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets

Scope {
    id: dockScope

    // Re-instantiate the layer surface cleanly when switching edge (bottom <-> left <-> right)
    // so wlr-layer-shell always gets crisp anchors and exclusiveZone; style/slider changes morph live at 144Hz!
    property bool _reloadingPos: false

    Connections {
        target: Store
        function onDockPositionChanged() {
            dockScope._reloadingPos = true
            posReloadTimer.restart()
        }
    }

    Timer {
        id: posReloadTimer
        interval: 20
        repeat: false
        onTriggered: dockScope._reloadingPos = false
    }

    Loader {
        id: dockLoader
        active: Store.dockEnabled && !dockScope._reloadingPos
        sourceComponent: dockWindowComp
    }

    Component {
        id: dockWindowComp

        PanelWindow {
            id: dockWin

            readonly property string pos: Store.dockPosition
            readonly property string styleId: Store.dockStyle
            readonly property string visMode: Store.dockVisibility
            readonly property string indStyle: Store.dockIndicator

            readonly property bool isVertical: pos === "left" || pos === "right"
            readonly property bool isBottom: pos === "bottom"
            readonly property bool isLeft: pos === "left"
            readonly property bool isRight: pos === "right"

            readonly property bool isPrism: styleId === "prism"
            readonly property bool isMacos: styleId === "macos"
            readonly property bool isIsland: styleId === "island"
            readonly property bool isCyber: styleId === "cyber"
            readonly property bool isTaskbar: styleId === "taskbar"
            readonly property bool isMinimal: styleId === "minimal"
            readonly property bool isAura: styleId === "aura"
            readonly property bool isArchbar: styleId === "archbar"

            readonly property int iconBase: Math.max(32, Math.min(60, Store.dockIconSize))
            readonly property real peakScale: Store.dockMagnify ? Math.max(1.0, Math.min(1.7, Store.dockMagScale / 100.0)) : 1.0
            readonly property int padMain: isMinimal ? 6 : (isTaskbar ? 8 : (isAura ? 11 : (isMacos ? 10 : 9)))
            readonly property int iconGap: isMinimal ? 4 : (isAura ? 8 : (isMacos ? 7 : 6))
            readonly property int barThickness: Math.round(iconBase + padMain * 2 + (isCyber ? 6 : 4))
            readonly property int edgeMargin: isTaskbar ? 0 : Math.max(0, Store.dockMargin)
            readonly property int cornerRadius: isTaskbar ? 0 : (isAura ? Math.round(barThickness / 2) : Math.max(0, Store.dockRadius))
            readonly property real bgAlpha: Math.max(0.25, Math.min(0.98, Store.dockOpacity / 100.0))
            readonly property color shellBg: isAura
                ? Colors.alpha(Colors.surfaceContainer, bgAlpha)
                : Colors.alpha(Colors.surfaceContainerLowest, bgAlpha)
            readonly property color shellCardBg: Colors.alpha(Colors.surfaceContainerHigh, Math.min(0.92, bgAlpha * 0.85))
            readonly property color shellBorder: isCyber
                ? Colors.alpha(Colors.primary, 0.75)
                : (isAura ? Colors.alpha(Colors.primary, 0.45)
                    : (isMacos ? Colors.alpha(Colors.m3onSurface, 0.22)
                        : (isMinimal ? Colors.glassBorderSubtle : Colors.glassBorder)))

            // Generous transparent headroom for hover magnification, tooltips, and context menu
            // (click-through outside dock & edge sensor via `mask: Region`)
            readonly property int windowExtent: Math.round(iconBase * Math.max(1.35, peakScale) + edgeMargin + 150)

            anchors {
                bottom: isBottom || isVertical
                top: isVertical
                left: isBottom || isLeft
                right: isBottom || isRight
            }

            implicitHeight: isVertical ? 0 : windowExtent
            implicitWidth: isVertical ? windowExtent : 0
            color: "transparent"

            WlrLayershell.namespace: "vela-dock"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            exclusionMode: visMode === "always" ? ExclusionMode.Normal : ExclusionMode.Ignore
            exclusiveZone: visMode === "always" ? Math.round(barThickness + edgeMargin) : 0

            // Input mask: ONLY visible dock shell + 6px edge reveal strip + open context menu accept clicks!
            mask: Region {
                item: dockWin.isRevealed ? dockInteractiveBounds : edgeSensor
                Region {
                    item: edgeSensor
                }
                Region {
                    item: ctxMenuMaskItem
                }
            }

            // =================================================================
            // SMART / AUTOHIDE VISIBILITY ENGINE
            // =================================================================
            property bool edgeHovered: false
            property bool dockHovered: false
            property bool menuHovered: false
            property bool revealSticky: false

            readonly property bool hasFullscreen: Hyprland.focusedWorkspace?.hasFullscreen ?? false
            readonly property bool workspaceHasWindows: {
                const ws = Hyprland.focusedWorkspace
                if (!ws || !ws.toplevels) return false
                const vals = ws.toplevels.values
                return vals && vals.length > 0
            }

            readonly property bool pointerActive: edgeHovered || dockHovered || menuHovered || ctxOpen || revealSticky
            readonly property bool isRevealed: {
                if (Store.dockStudioOpen) return true
                if (pointerActive) return true
                if (hasFullscreen) return false
                if (visMode === "always") return true
                if (visMode === "smart") return !workspaceHasWindows
                return false // autohide
            }

            property real revealAnim: isRevealed ? 1.0 : 0.0
            Behavior on revealAnim {
                NumberAnimation {
                    duration: dockWin.isRevealed ? 240 : 190
                    easing.type: dockWin.isRevealed ? Easing.OutQuint : Easing.InCubic
                }
            }

            Timer {
                id: hideGraceTimer
                interval: 420
                repeat: false
                onTriggered: {
                    if (!dockWin.edgeHovered && !dockWin.dockHovered && !dockWin.menuHovered && !dockWin.ctxOpen) {
                        dockWin.revealSticky = false
                    }
                }
            }

            function touchHover() {
                revealSticky = true
                hideGraceTimer.stop()
            }

            function scheduleHideGrace() {
                if (!edgeHovered && !dockHovered && !menuHovered && !ctxOpen) {
                    hideGraceTimer.restart()
                }
            }

            // =================================================================
            // LIVE CLOCK & MEDIA (for Taskbar & Dynamic Islands pods)
            // =================================================================
            property string dockClock: Qt.formatDateTime(new Date(), "HH:mm")
            Timer {
                interval: 10000
                running: dockWin.isTaskbar || dockWin.isIsland
                repeat: true
                onTriggered: dockWin.dockClock = Qt.formatDateTime(new Date(), "HH:mm")
            }

            readonly property var activePlayer: {
                const players = Mpris.players.values
                if (!players || players.length === 0) return null
                for (let i = 0; i < players.length; i++) {
                    if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
                }
                return players[0]
            }
            readonly property bool isMediaPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

            // =================================================================
            // CONTINUOUS WAVE MAGNIFICATION TRACKER
            // =================================================================
            property bool stripHovered: false
            property real hoverAxisPos: -1000
            property int hoveredAppIdx: -1
            property string hoveredLabel: ""
            property string hoveredSublabel: ""
            property real hoveredCenterAxis: 0

            // =================================================================
            // RIGHT-CLICK CONTEXT MENU STATE
            // =================================================================
            property bool ctxOpen: false
            property var ctxApp: null
            property real ctxAnchorAxis: 0

            function openContextMenu(appData, anchorAxis) {
                ctxApp = appData
                ctxAnchorAxis = anchorAxis
                ctxOpen = true
                touchHover()
            }

            function closeContextMenu() {
                ctxOpen = false
                ctxApp = null
                scheduleHideGrace()
            }

            // =================================================================
            // SMART PINNED + RUNNING APPS MERGER (REACTIVE WAYLAND TOPLEVELS)
            // =================================================================
            function normKey(raw) {
                if (!raw) return ""
                let s = String(raw).trim().toLowerCase()
                if (s.endsWith(".desktop")) s = s.slice(0, -8)
                const parts = s.split(".")
                const tail = parts[parts.length - 1]
                if (tail === "dolphin") return "org.kde.dolphin"
                if (tail === "pavucontrol") return "pavucontrol"
                if (s.includes("firefox")) return "firefox"
                if (s.includes("kitty")) return "kitty"
                if (s.includes("chromium")) return "chromium"
                if (s.includes("brave")) return "brave"
                if (s.includes("code")) return "code"
                if (s.includes("antigravity")) return "antigravity"
                return s
            }

            function fallbackGlyph(idStr) {
                const s = String(idStr || "").toLowerCase()
                if (s.includes("kitty") || s.includes("term") || s.includes("alacritty")) return "󰆍"
                if (s.includes("firefox") || s.includes("zen")) return "󰈹"
                if (s.includes("chrom") || s.includes("brave")) return "󰊯"
                if (s.includes("dolphin") || s.includes("thunar") || s.includes("files")) return "󰉋"
                if (s.includes("btop") || s.includes("htop")) return "󰍛"
                if (s.includes("pavucontrol") || s.includes("audio")) return "󰕾"
                if (s.includes("blueman") || s.includes("blue")) return "󰂯"
                if (s.includes("code") || s.includes("vscod")) return "󰨞"
                if (s.includes("antigravity")) return "󰚩"
                if (s.includes("discord") || s.includes("vesktop")) return "󰙯"
                if (s.includes("spotify")) return "󰓇"
                if (s.includes("steam")) return "󰓓"
                if (s.includes("obs")) return "󰑋"
                if (s.includes("mpv") || s.includes("vlc")) return "󰐊"
                if (s.includes("nwg") || s.includes("qt6ct") || s.includes("kvantum")) return "󰏘"
                return "󰣆"
            }

            function findCatalogApp(key) {
                const list = Store.apps || []
                const k = normKey(key)
                const rawLower = String(key || "").toLowerCase()
                for (let i = 0; i < list.length; i++) {
                    const a = list[i]
                    const aid = String(a.id || "").toLowerCase()
                    const aname = String(a.name || "").toLowerCase()
                    const aicon = String(a.icon || "").toLowerCase()
                    if (aid === rawLower || normKey(aid) === k) return a
                    if (aicon === rawLower || normKey(aicon) === k) return a
                    if (rawLower === "kitty" && aid === "vela-terminal") return a
                    if (aname === rawLower) return a
                }
                for (let i = 0; i < list.length; i++) {
                    const a = list[i]
                    const aid = String(a.id || "").toLowerCase()
                    if (k.length >= 3 && (aid.includes(k) || k.includes(aid))) return a
                }
                return null
            }

            function resolveIcon(iconName, appId) {
                const tries = []
                if (iconName) tries.push(iconName)
                if (appId) {
                    tries.push(appId)
                    const parts = String(appId).split(".")
                    if (parts.length > 1) tries.push(parts[parts.length - 1])
                    tries.push(String(appId).toLowerCase())
                }
                const norm = normKey(appId)
                if (norm === "org.kde.dolphin") tries.push("system-file-manager", "dolphin")
                if (norm === "pavucontrol") tries.push("multimedia-volume-control", "pavucontrol")
                if (norm === "btop") tries.push("btop", "utilities-system-monitor")
                if (norm === "kitty") tries.push("kitty", "utilities-terminal")
                if (norm === "firefox") tries.push("firefox", "web-browser")
                for (let i = 0; i < tries.length; i++) {
                    const p = Quickshell.iconPath(tries[i], true)
                    if (p && p.length > 0) return p
                }
                return ""
            }

            readonly property var dockApps: {
                // Touch reactive signals so QML re-evaluates on window open/close/focus/pin changes
                const _activeTl = ToplevelManager.activeToplevel
                const _hyprAct = Hyprland.activeToplevel
                const _appsCatalog = Store.apps
                const pinnedIds = Array.isArray(Store.dockPinned) ? Store.dockPinned : []
                const liveTls = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []

                const byKey = {}
                const ordered = []

                // 1. Add all pinned apps first
                for (let i = 0; i < pinnedIds.length; i++) {
                    const rawId = String(pinnedIds[i])
                    const k = normKey(rawId)
                    if (!k || byKey[k]) continue
                    const cat = findCatalogApp(rawId)
                    const name = cat ? cat.name : (rawId.split(".").pop().replace(/^\w/, c => c.toUpperCase()))
                    const execCmd = cat ? cat.exec : (k === "org.kde.dolphin" ? "dolphin" : (k === "btop" ? "kitty -e btop" : rawId))
                    const iconPath = resolveIcon(cat ? cat.icon : "", rawId)
                    const entry = {
                        key: k,
                        appId: rawId,
                        name: name,
                        exec: execCmd,
                        iconPath: iconPath,
                        glyph: cat ? (cat.glyph || fallbackGlyph(rawId)) : fallbackGlyph(rawId),
                        pinned: true,
                        running: false,
                        active: false,
                        windowCount: 0,
                        toplevels: [],
                        activeTitle: ""
                    }
                    byKey[k] = entry
                    ordered.push(entry)
                }

                // 2. Merge live running Wayland toplevels
                if (liveTls && liveTls.length > 0) {
                    for (let i = 0; i < liveTls.length; i++) {
                        const tl = liveTls[i]
                        if (!tl) continue
                        const rawAppId = tl.appId || ""
                        if (!rawAppId) continue
                        const k = normKey(rawAppId)
                        let entry = byKey[k]
                        if (!entry) {
                            if (!Store.dockShowRunning) continue
                            const cat = findCatalogApp(rawAppId)
                            const pretty = cat
                                ? cat.name
                                : rawAppId.split(".").pop().replace(/[-_]/g, " ").replace(/\b\w/g, c => c.toUpperCase())
                            entry = {
                                key: k,
                                appId: rawAppId,
                                name: pretty,
                                exec: cat ? cat.exec : rawAppId,
                                iconPath: resolveIcon(cat ? cat.icon : "", rawAppId),
                                glyph: cat ? (cat.glyph || fallbackGlyph(rawAppId)) : fallbackGlyph(rawAppId),
                                pinned: false,
                                running: true,
                                active: false,
                                windowCount: 0,
                                toplevels: [],
                                activeTitle: ""
                            }
                            byKey[k] = entry
                            ordered.push(entry)
                        }
                        entry.running = true
                        entry.windowCount += 1
                        entry.toplevels.push(tl)
                        if (tl.activated) {
                            entry.active = true
                            entry.activeTitle = tl.title || ""
                        } else if (!entry.activeTitle && tl.title) {
                            entry.activeTitle = tl.title
                        }
                    }
                }
                return ordered
            }

            function activateOrLaunch(app, forceNew) {
                if (!app) return
                closeContextMenu()
                if (!forceNew && app.toplevels && app.toplevels.length > 0) {
                    const tls = app.toplevels
                    if (tls.length === 1) {
                        tls[0].activate()
                    } else {
                        let curIdx = -1
                        for (let i = 0; i < tls.length; i++) {
                            if (tls[i].activated) {
                                curIdx = i
                                break
                            }
                        }
                        const nextTl = tls[(curIdx + 1) % tls.length]
                        nextTl.activate()
                    }
                } else {
                    Store.recordAppLaunch(app.appId)
                    Store.runCmd(app.exec)
                }
            }

            // =================================================================
            // EDGE REVEAL HOTZONE (6px ultra-thin invisible edge sensor)
            // =================================================================
            Item {
                id: edgeSensor
                anchors.bottom: dockWin.isBottom || dockWin.isVertical ? parent.bottom : undefined
                anchors.top: dockWin.isVertical ? parent.top : undefined
                anchors.left: dockWin.isBottom || dockWin.isLeft ? parent.left : undefined
                anchors.right: dockWin.isBottom || dockWin.isRight ? parent.right : undefined
                height: dockWin.isVertical ? parent.height : 6
                width: dockWin.isVertical ? 6 : parent.width
                z: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        dockWin.edgeHovered = true
                        dockWin.touchHover()
                    }
                    onExited: {
                        dockWin.edgeHovered = false
                        dockWin.scheduleHideGrace()
                    }
                }
            }

            // =================================================================
            // FLOATING TOOLTIP PILL (above bottom dock, or beside vertical dock)
            // =================================================================
            Rectangle {
                id: tooltipPill
                visible: Store.dockShowLabels && dockWin.stripHovered && dockWin.hoveredLabel.length > 0 && !dockWin.ctxOpen && dockWin.revealAnim > 0.7
                z: 40
                radius: dockWin.isCyber ? 6 : 12
                color: Colors.alpha(Colors.surfaceContainerLowest, 0.92)
                border.width: 1
                border.color: dockWin.isCyber ? Colors.primary : Colors.glassBorder
                width: Math.min(260, tipCol.implicitWidth + 22)
                height: tipCol.implicitHeight + 12

                x: {
                    if (dockWin.isBottom) {
                        const raw = dockWin.hoveredCenterAxis - width / 2
                        return Math.max(12, Math.min(dockWin.width - width - 12, raw))
                    }
                    if (dockWin.isLeft) {
                        return Math.round(dockWin.edgeMargin + dockWin.barThickness + (dockWin.iconBase * (dockWin.peakScale - 1)) + 16)
                    }
                    return Math.round(dockWin.width - dockWin.edgeMargin - dockWin.barThickness - (dockWin.iconBase * (dockWin.peakScale - 1)) - width - 16)
                }
                y: {
                    if (dockWin.isBottom) {
                        const liftExtra = Math.round(dockWin.iconBase * (dockWin.peakScale - 1) * 0.75)
                        return Math.max(6, Math.round(dockWin.height - dockWin.edgeMargin - dockWin.barThickness - liftExtra - height - 16))
                    }
                    const raw = dockWin.hoveredCenterAxis - height / 2
                    return Math.max(12, Math.min(dockWin.height - height - 12, raw))
                }

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                Column {
                    id: tipCol
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dockWin.hoveredLabel
                        font.family: dockWin.isCyber ? "JetBrainsMono Nerd Font" : "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Colors.m3onSurface
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 232)
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        visible: dockWin.hoveredSublabel.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dockWin.hoveredSublabel
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Colors.primary
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 232)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // =================================================================
            // RIGHT-CLICK FLOATING CONTEXT MENU (Pin/Unpin, New, RTX, Close)
            // =================================================================
            Item {
                id: ctxMenuMaskItem
                z: 50
                width: dockWin.ctxOpen ? (ctxCol.implicitWidth + 24) : 0
                height: dockWin.ctxOpen ? (ctxCol.implicitHeight + 18) : 0
                x: {
                    if (!dockWin.ctxOpen) return 0
                    if (dockWin.isBottom) {
                        const raw = dockWin.ctxAnchorAxis - width / 2
                        return Math.max(12, Math.min(dockWin.width - width - 12, raw))
                    }
                    if (dockWin.isLeft) return Math.round(dockWin.edgeMargin + dockWin.barThickness + 14)
                    return Math.round(dockWin.width - dockWin.edgeMargin - dockWin.barThickness - width - 14)
                }
                y: {
                    if (!dockWin.ctxOpen) return 0
                    if (dockWin.isBottom) {
                        return Math.max(6, Math.round(dockWin.height - dockWin.edgeMargin - dockWin.barThickness - height - 14))
                    }
                    const raw = dockWin.ctxAnchorAxis - height / 2
                    return Math.max(12, Math.min(dockWin.height - height - 12, raw))
                }

                Rectangle {
                    anchors.fill: parent
                    visible: dockWin.ctxOpen
                    radius: dockWin.isCyber ? 10 : 18
                    color: Colors.alpha(Colors.surfaceContainerLowest, 0.94)
                    border.width: 1
                    border.color: Colors.glassBorder

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            dockWin.menuHovered = true
                            dockWin.touchHover()
                        }
                        onExited: {
                            dockWin.menuHovered = false
                            ctxAutoCloseTimer.restart()
                        }
                    }

                    Timer {
                        id: ctxAutoCloseTimer
                        interval: 600
                        repeat: false
                        onTriggered: {
                            if (!dockWin.menuHovered && !dockWin.dockHovered) {
                                dockWin.closeContextMenu()
                            }
                        }
                    }

                    ColumnLayout {
                        id: ctxCol
                        anchors.centerIn: parent
                        width: 204
                        spacing: 4

                        // App Header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 2
                            spacing: 6
                            Text {
                                text: dockWin.ctxApp ? dockWin.ctxApp.name : ""
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: Colors.primary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: Colors.m3onSurfaceVariant
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dockWin.closeContextMenu()
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Colors.glassBorderSubtle }

                        // Action: New Instance
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 10
                            color: actNewHover.containsMouse ? Colors.alpha(Colors.primary, 0.22) : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: "󰐊"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Colors.primary }
                                Text { text: "Mở cửa sổ mới"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface; Layout.fillWidth: true }
                            }
                            MouseArea {
                                id: actNewHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: dockWin.activateOrLaunch(dockWin.ctxApp, true)
                            }
                        }

                        // Action: Launch on RTX 4050
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 10
                            color: actNvHover.containsMouse ? Colors.alpha(Colors.tertiary, 0.22) : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: "󰢮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Colors.tertiary }
                                Text { text: "Chạy bằng RTX 4050"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface; Layout.fillWidth: true }
                            }
                            MouseArea {
                                id: actNvHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (dockWin.ctxApp) {
                                        const cmd = `prime-run ${dockWin.ctxApp.exec}`
                                        dockWin.closeContextMenu()
                                        Store.runCmd(cmd)
                                    }
                                }
                            }
                        }

                        // Action: Pin / Unpin
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 10
                            color: actPinHover.containsMouse ? Colors.alpha(Colors.primary, 0.22) : "transparent"
                            readonly property bool isPinnedNow: dockWin.ctxApp ? Store.isDockAppPinned(dockWin.ctxApp.appId) : false
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: parent.parent.isPinnedNow ? "󰤰" : "󰐃"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Colors.primary }
                                Text { text: parent.parent.isPinnedNow ? "Bỏ ghim khỏi Dock" : "Ghim vào Dock"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface; Layout.fillWidth: true }
                            }
                            MouseArea {
                                id: actPinHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (dockWin.ctxApp) {
                                        const id = dockWin.ctxApp.appId
                                        dockWin.closeContextMenu()
                                        Store.togglePinDockApp(id)
                                    }
                                }
                            }
                        }

                        // Action: Close Window (only when running)
                        Rectangle {
                            visible: dockWin.ctxApp !== null && dockWin.ctxApp.running
                            Layout.fillWidth: true; height: 28; radius: 10
                            color: actCloseHover.containsMouse ? Colors.alpha(Colors.error, 0.24) : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: "󰅖"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Colors.error }
                                Text {
                                    text: dockWin.ctxApp && dockWin.ctxApp.windowCount > 1
                                        ? `Đóng cửa sổ (${dockWin.ctxApp.windowCount})`
                                        : "Đóng cửa sổ"
                                    font.family: "Inter"; font.pixelSize: 11; color: Colors.error; Layout.fillWidth: true
                                }
                            }
                            MouseArea {
                                id: actCloseHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (dockWin.ctxApp && dockWin.ctxApp.toplevels && dockWin.ctxApp.toplevels.length > 0) {
                                        const tl = dockWin.ctxApp.toplevels[0]
                                        dockWin.closeContextMenu()
                                        tl.close()
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Colors.glassBorderSubtle }

                        // Action: Open Dock Studio
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 10
                            color: actStudioHover.containsMouse ? Colors.alpha(Colors.primary, 0.22) : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: "󱂬"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Colors.primary }
                                Text { text: "Đổi kiểu & Config Dock"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface; Layout.fillWidth: true }
                            }
                            MouseArea {
                                id: actStudioHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dockWin.closeContextMenu()
                                    Store.toggleDockStudio()
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // INTERACTIVE DOCK CONTAINER (MASKED TO EXACT VISUAL FOOTPRINT)
            // =================================================================
            Item {
                id: dockInteractiveBounds
                z: 10

                // Slide cleanly off screen edge when hidden
                readonly property real slideDist: dockWin.barThickness + dockWin.edgeMargin + 36
                opacity: Math.max(0.0, Math.min(1.0, dockWin.revealAnim * 1.15))

                transform: Translate {
                    x: dockWin.isLeft
                        ? -(1.0 - dockWin.revealAnim) * dockInteractiveBounds.slideDist
                        : (dockWin.isRight ? (1.0 - dockWin.revealAnim) * dockInteractiveBounds.slideDist : 0)
                    y: dockWin.isBottom ? (1.0 - dockWin.revealAnim) * dockInteractiveBounds.slideDist : 0
                }

                // Size & placement adapt cleanly for Taskbar (full edge) vs Floating Capsules / Islands
                width: {
                    if (dockWin.isBottom) {
                        return dockWin.isTaskbar ? parent.width : Math.min(parent.width - 24, dockInnerContainer.implicitWidth)
                    }
                    return dockWin.isTaskbar ? dockWin.barThickness : dockInnerContainer.implicitWidth
                }
                height: {
                    if (dockWin.isVertical) {
                        return dockWin.isTaskbar ? parent.height : Math.min(parent.height - 24, dockInnerContainer.implicitHeight)
                    }
                    return dockWin.isTaskbar ? dockWin.barThickness : dockInnerContainer.implicitHeight
                }

                anchors.horizontalCenter: dockWin.isBottom ? parent.horizontalCenter : undefined
                anchors.verticalCenter: dockWin.isVertical ? parent.verticalCenter : undefined
                anchors.bottom: dockWin.isBottom ? parent.bottom : undefined
                anchors.bottomMargin: dockWin.isBottom ? dockWin.edgeMargin : 0
                anchors.left: dockWin.isLeft ? parent.left : undefined
                anchors.leftMargin: dockWin.isLeft ? dockWin.edgeMargin : 0
                anchors.right: dockWin.isRight ? parent.right : undefined
                anchors.rightMargin: dockWin.isRight ? dockWin.edgeMargin : 0

                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }

                // Base hover / right-click listener over the dock footprint
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    onEntered: {
                        dockWin.dockHovered = true
                        dockWin.touchHover()
                    }
                    onExited: {
                        dockWin.dockHovered = false
                        dockWin.stripHovered = false
                        dockWin.hoveredAppIdx = -1
                        dockWin.hoveredLabel = ""
                        dockWin.scheduleHideGrace()
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Store.toggleDockStudio()
                        }
                    }
                }

                // =============================================================
                // REUSABLE UTILITY ICON BUTTON COMPONENT
                // =============================================================
                component DockUtilBtn: Item {
                    id: ubtn
                    property string iconText: ""
                    property string tipText: ""
                    property bool activeState: false
                    property color accentColor: Colors.primary
                    signal triggered(var mouse)

                    readonly property int tileSz: Math.max(30, Math.round(dockWin.iconBase * 0.86))
                    implicitWidth: tileSz
                    implicitHeight: tileSz

                    Rectangle {
                        anchors.centerIn: parent
                        width: ubtn.tileSz
                        height: ubtn.tileSz
                        radius: dockWin.isCyber ? 8 : Math.round(ubtn.tileSz * 0.34)
                        color: ubtn.activeState
                            ? ubtn.accentColor
                            : (uHover.containsMouse ? Colors.alpha(ubtn.accentColor, 0.22) : Colors.glassHighlight)
                        border.width: ubtn.activeState || uHover.containsMouse ? 1 : (dockWin.isCyber ? 1 : 0)
                        border.color: ubtn.activeState || uHover.containsMouse ? ubtn.accentColor : Colors.glassBorderSubtle
                        scale: uHover.pressed ? 0.90 : (uHover.containsMouse ? 1.08 : 1.0)

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: ubtn.iconText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Math.max(13, Math.round(ubtn.tileSz * 0.44))
                            color: ubtn.activeState ? Colors.m3onPrimary : (uHover.containsMouse ? ubtn.accentColor : Colors.m3onSurface)
                        }
                    }

                    MouseArea {
                        id: uHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            dockWin.dockHovered = true
                            dockWin.touchHover()
                            dockWin.stripHovered = true
                            dockWin.hoveredLabel = ubtn.tipText
                            dockWin.hoveredSublabel = ""
                            const pt = ubtn.mapToItem(dockWin.contentItem, ubtn.width / 2, ubtn.height / 2)
                            dockWin.hoveredCenterAxis = dockWin.isVertical ? pt.y : pt.x
                        }
                        onExited: {
                            if (dockWin.hoveredLabel === ubtn.tipText) {
                                dockWin.hoveredLabel = ""
                            }
                        }
                        onClicked: mouse => ubtn.triggered(mouse)
                    }
                }

                // =============================================================
                // REUSABLE RUNNING INDICATOR COMPONENT (5 STYLES!)
                // =============================================================
                component RunningIndicator: Item {
                    id: rInd
                    property bool running: false
                    property bool active: false
                    property int winCount: 0

                    visible: running && dockWin.indStyle !== "glow" && dockWin.indStyle !== "ring"
                    width: dockWin.isVertical ? 5 : (dockWin.indStyle === "dot" ? (winCount > 1 ? 14 : 6) : (active ? 20 : 10))
                    height: dockWin.isVertical ? (dockWin.indStyle === "dot" ? (winCount > 1 ? 14 : 6) : (active ? 20 : 10)) : 4

                    // Pill or Bar indicator
                    Rectangle {
                        visible: dockWin.indStyle === "pill" || dockWin.indStyle === "bar"
                        anchors.centerIn: parent
                        width: dockWin.isVertical ? (dockWin.indStyle === "bar" ? 3 : 4) : (rInd.active ? (dockWin.indStyle === "bar" ? 22 : 18) : 8)
                        height: dockWin.isVertical ? (rInd.active ? (dockWin.indStyle === "bar" ? 22 : 18) : 8) : (dockWin.indStyle === "bar" ? 3 : 4)
                        radius: dockWin.indStyle === "bar" ? 1.5 : 2
                        color: rInd.active ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.55)

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    // Classic Dot indicator (double dots for 2+ windows)
                    GridLayout {
                        visible: dockWin.indStyle === "dot"
                        anchors.centerIn: parent
                        flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                        rows: dockWin.isVertical ? -1 : 1
                        columns: dockWin.isVertical ? 1 : -1
                        rowSpacing: 3
                        columnSpacing: 3

                        Repeater {
                            model: Math.min(3, Math.max(1, rInd.winCount))
                            delegate: Rectangle {
                                width: rInd.active ? 5 : 4
                                height: rInd.active ? 5 : 4
                                radius: 2.5
                                color: rInd.active ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.65)
                            }
                        }
                    }
                }

                // =============================================================
                // APP STRIP COMPONENT (REUSED ACROSS ALL 6 PRESETS!)
                // =============================================================
                component AppStrip: Item {
                    id: appStripRoot
                    implicitWidth: appsGrid.implicitWidth
                    implicitHeight: appsGrid.implicitHeight

                    GridLayout {
                        id: appsGrid
                        anchors.centerIn: parent
                        flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                        rows: dockWin.isVertical ? -1 : 1
                        columns: dockWin.isVertical ? 1 : -1
                        rowSpacing: dockWin.iconGap
                        columnSpacing: dockWin.iconGap

                        Repeater {
                            model: dockWin.dockApps
                            delegate: Item {
                                id: appSlot
                                required property var modelData
                                required property int index

                                // Continuous parabolic Gaussian wave magnification across neighbors!
                                readonly property real slotCenterAxis: dockWin.isVertical ? (y + height / 2) : (x + width / 2)
                                readonly property real waveDist: dockWin.stripHovered && dockWin.hoverAxisPos >= 0
                                    ? Math.abs(slotCenterAxis - dockWin.hoverAxisPos) / Math.max(24, dockWin.iconBase + dockWin.iconGap)
                                    : 99
                                readonly property real magFactor: (Store.dockMagnify && dockWin.stripHovered && waveDist < 2.6)
                                    ? (1.0 + (dockWin.peakScale - 1.0) * Math.exp(-waveDist * waveDist * 1.15))
                                    : 1.0

                                property real animScale: magFactor
                                Behavior on animScale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                // Bounce offset on launch click
                                property real clickBounce: 0
                                SequentialAnimation {
                                    id: launchBounceAnim
                                    NumberAnimation { target: appSlot; property: "clickBounce"; to: -12; duration: 130; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: appSlot; property: "clickBounce"; to: 0; duration: 240; easing.type: Easing.OutBounce }
                                }

                                readonly property int effMain: Math.round(dockWin.iconBase * (dockWin.isMacos ? (1.0 + (animScale - 1.0) * 0.72) : (1.0 + (animScale - 1.0) * 0.35)))
                                Layout.preferredWidth: dockWin.isVertical ? dockWin.iconBase : effMain
                                Layout.preferredHeight: dockWin.isVertical ? effMain : dockWin.iconBase
                                Layout.alignment: Qt.AlignCenter

                                // Hover lift perpendicular to screen edge
                                readonly property real liftPx: (animScale - 1.0) * dockWin.iconBase * (dockWin.isMacos ? 0.58 : 0.34)

                                // Main visual icon tile
                                Item {
                                    id: visualTile
                                    anchors.centerIn: parent
                                    width: dockWin.iconBase
                                    height: dockWin.iconBase
                                    scale: appSlot.animScale

                                    transform: Translate {
                                        y: dockWin.isBottom ? (-appSlot.liftPx + appSlot.clickBounce) : 0
                                        x: dockWin.isLeft
                                            ? (appSlot.liftPx - appSlot.clickBounce)
                                            : (dockWin.isRight ? (-appSlot.liftPx + appSlot.clickBounce) : 0)
                                    }

                                    // Glow indicator aura (when dockIndicator === "glow")
                                    Rectangle {
                                        visible: modelData.running && dockWin.indStyle === "glow"
                                        anchors.centerIn: parent
                                        width: parent.width + 6
                                        height: parent.height + 6
                                        radius: tileBg.radius + 3
                                        color: modelData.active
                                            ? Colors.alpha(Colors.primary, 0.34)
                                            : Colors.alpha(Colors.tertiary, 0.18)
                                        Behavior on color { ColorAnimation { duration: 160 } }
                                    }

                                    // Tile Backdrop
                                    Rectangle {
                                        id: tileBg
                                        anchors.fill: parent
                                        radius: dockWin.isCyber
                                            ? 9
                                            : (dockWin.isMinimal ? Math.round(width * 0.28) : Math.round(width * 0.30))
                                        color: {
                                            if (modelData.active) {
                                                return dockWin.isCyber
                                                    ? Colors.alpha(Colors.primary, 0.26)
                                                    : Colors.alpha(Colors.primary, 0.18)
                                            }
                                            if (slotMouse.containsMouse) {
                                                return dockWin.isMacos
                                                    ? Colors.alpha(Colors.m3onSurface, 0.12)
                                                    : Colors.alpha(Colors.primary, 0.14)
                                            }
                                            if (dockWin.isTaskbar && modelData.running) {
                                                return Colors.alpha(Colors.m3onSurface, 0.08)
                                            }
                                            if (modelData.iconPath.length === 0) {
                                                return Colors.glassHighlight
                                            }
                                            return dockWin.isCyber ? Colors.alpha(Colors.surfaceContainerHigh, 0.55) : "transparent"
                                        }
                                        border.width: {
                                            if (modelData.running && dockWin.indStyle === "ring") return modelData.active ? 2 : 1.2
                                            if (dockWin.isCyber && (modelData.active || slotMouse.containsMouse)) return 1.5
                                            if (modelData.active && (dockWin.isPrism || dockWin.isTaskbar)) return 1
                                            return 0
                                        }
                                        border.color: modelData.active
                                            ? Colors.primary
                                            : (modelData.running && dockWin.indStyle === "ring" ? Colors.alpha(Colors.secondary, 0.65) : Colors.glassBorder)

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        // System Icon (Real PNG/SVG Icon)
                                        IconImage {
                                            visible: modelData.iconPath.length > 0
                                            anchors.centerIn: parent
                                            implicitSize: Math.round(dockWin.iconBase * (dockWin.isMacos ? 0.82 : 0.72))
                                            source: modelData.iconPath
                                            mipmap: true
                                            asynchronous: true
                                        }

                                        // Nerd Font Fallback Glyph
                                        Text {
                                            visible: modelData.iconPath.length === 0
                                            anchors.centerIn: parent
                                            text: modelData.glyph
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: Math.round(dockWin.iconBase * 0.48)
                                            color: modelData.active ? Colors.primary : Colors.m3onSurface
                                        }

                                        // Multi-window Count Micro Badge (when 2+ windows open)
                                        Rectangle {
                                            visible: modelData.windowCount > 1
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: -2
                                            width: 15
                                            height: 15
                                            radius: dockWin.isCyber ? 4 : 7.5
                                            color: modelData.active ? Colors.primary : Colors.surfaceContainerHighest
                                            border.width: 1
                                            border.color: Colors.surfaceContainerLowest

                                            Text {
                                                anchors.centerIn: parent
                                                text: String(modelData.windowCount)
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.active ? Colors.m3onPrimary : Colors.m3onSurface
                                            }
                                        }
                                    }
                                }

                                // Running Indicator anchored neatly on the outer edge of the slot
                                RunningIndicator {
                                    running: modelData.running
                                    active: modelData.active
                                    winCount: modelData.windowCount
                                    anchors.horizontalCenter: dockWin.isBottom ? parent.horizontalCenter : undefined
                                    anchors.verticalCenter: dockWin.isVertical ? parent.verticalCenter : undefined
                                    anchors.bottom: dockWin.isBottom ? parent.bottom : undefined
                                    anchors.bottomMargin: dockWin.isBottom ? -6 : 0
                                    anchors.left: dockWin.isLeft ? parent.left : undefined
                                    anchors.leftMargin: dockWin.isLeft ? -6 : 0
                                    anchors.right: dockWin.isRight ? parent.right : undefined
                                    anchors.rightMargin: dockWin.isRight ? -6 : 0
                                }

                                MouseArea {
                                    id: slotMouse
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor

                                    function updateWave(mx, my) {
                                        dockWin.dockHovered = true
                                        dockWin.stripHovered = true
                                        dockWin.touchHover()
                                        dockWin.hoveredAppIdx = index
                                        dockWin.hoveredLabel = modelData.name
                                        if (modelData.running) {
                                            const cntTag = modelData.windowCount > 1 ? ` [${modelData.windowCount}]` : ""
                                            const t = modelData.activeTitle
                                            dockWin.hoveredSublabel = t
                                                ? (t.length > 26 ? t.slice(0, 26) + "…" : t) + cntTag
                                                : (modelData.active ? "● Đang mở" + cntTag : "Đang chạy" + cntTag)
                                        } else {
                                            dockWin.hoveredSublabel = ""
                                        }
                                        const ptInStrip = appSlot.mapToItem(appsGrid, mx, my)
                                        dockWin.hoverAxisPos = dockWin.isVertical ? ptInStrip.y : ptInStrip.x
                                        const ptInWin = appSlot.mapToItem(dockWin.contentItem, appSlot.width / 2, appSlot.height / 2)
                                        dockWin.hoveredCenterAxis = dockWin.isVertical ? ptInWin.y : ptInWin.x
                                    }

                                    onEntered: updateWave(width / 2, height / 2)
                                    onPositionChanged: m => updateWave(m.x, m.y)
                                    onExited: {
                                        if (dockWin.hoveredAppIdx === index) {
                                            dockWin.hoveredAppIdx = -1
                                        }
                                    }
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            const pt = appSlot.mapToItem(dockWin.contentItem, appSlot.width / 2, appSlot.height / 2)
                                            dockWin.openContextMenu(modelData, dockWin.isVertical ? pt.y : pt.x)
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            launchBounceAnim.restart()
                                            dockWin.activateOrLaunch(modelData, true)
                                        } else {
                                            if (!modelData.running) launchBounceAnim.restart()
                                            dockWin.activateOrLaunch(modelData, false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // PRESET LAYOUT ENGINE:
                //  - Mode A: Dynamic Islands (3 separate floating glass pods)
                //  - Mode B: Full-Width Glass Taskbar (Left / Center / Right zones)
                //  - Mode C: Unified Floating Capsule (Prism / macOS / Cyber / Minimal)
                // =============================================================
                Item {
                    id: dockInnerContainer
                    anchors.fill: dockWin.isTaskbar ? parent : undefined
                    anchors.centerIn: dockWin.isTaskbar ? undefined : parent
                    implicitWidth: dockWin.isIsland
                        ? islandsLayout.implicitWidth
                        : (dockWin.isTaskbar ? dockWin.barThickness : unifiedCapsule.implicitWidth)
                    implicitHeight: dockWin.isIsland
                        ? islandsLayout.implicitHeight
                        : (dockWin.isTaskbar ? dockWin.barThickness : unifiedCapsule.implicitHeight)

                    // =========================================================
                    // PRESET 3: DYNAMIC ISLANDS (3 SPLIT FLOATING PODS!)
                    // =========================================================
                    GridLayout {
                        id: islandsLayout
                        visible: dockWin.isIsland
                        anchors.centerIn: parent
                        flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                        rows: dockWin.isVertical ? -1 : 1
                        columns: dockWin.isVertical ? 1 : -1
                        rowSpacing: 10
                        columnSpacing: 10

                        // POD 1: Vela Prism Launcher Pod
                        Rectangle {
                            id: islandPodLeft
                            implicitWidth: dockWin.isVertical ? dockWin.barThickness : (pod1Row.implicitWidth + 18)
                            implicitHeight: dockWin.isVertical ? (pod1Row.implicitHeight + 18) : dockWin.barThickness
                            radius: dockWin.cornerRadius
                            color: dockWin.shellBg
                            border.width: 1
                            border.color: dockWin.shellBorder

                            GridLayout {
                                id: pod1Row
                                anchors.centerIn: parent
                                flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                                rows: dockWin.isVertical ? -1 : 1
                                columns: dockWin.isVertical ? 1 : -1
                                rowSpacing: 6
                                columnSpacing: 6

                                DockUtilBtn {
                                    iconText: "◆"
                                    tipText: "App Launcher (Super+Space)"
                                    activeState: Store.launcherOpen
                                    onTriggered: Store.toggleLauncher()
                                }

                                // Active Workspace pill
                                Rectangle {
                                    width: Math.max(26, Math.round(dockWin.iconBase * 0.62))
                                    height: Math.max(26, Math.round(dockWin.iconBase * 0.62))
                                    radius: width / 2
                                    color: Colors.alpha(Colors.primary, 0.22)
                                    border.width: 1
                                    border.color: Colors.alpha(Colors.primary, 0.55)
                                    Text {
                                        anchors.centerIn: parent
                                        text: String(Hyprland.focusedWorkspace?.id ?? 1)
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Colors.primary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.toggleLayout()
                                    }
                                }
                            }
                        }

                        // POD 2: Core Apps Island
                        Rectangle {
                            id: islandPodApps
                            implicitWidth: dockWin.isVertical ? dockWin.barThickness : (islandAppStrip.implicitWidth + dockWin.padMain * 2 + 10)
                            implicitHeight: dockWin.isVertical ? (islandAppStrip.implicitHeight + dockWin.padMain * 2 + 10) : dockWin.barThickness
                            radius: dockWin.cornerRadius
                            color: dockWin.shellBg
                            border.width: 1
                            border.color: dockWin.shellBorder

                            // Subtle prism top glint
                            Rectangle {
                                visible: !dockWin.isVertical
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.max(24, parent.width - dockWin.cornerRadius * 2)
                                height: 1
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.35; color: Colors.alpha(Colors.primary, 0.55) }
                                    GradientStop { position: 0.65; color: Colors.alpha(Colors.tertiary, 0.55) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            AppStrip {
                                id: islandAppStrip
                                anchors.centerIn: parent
                            }
                        }

                        // POD 3: Live Media + Dock Studio Utils Pod
                        Rectangle {
                            id: islandPodRight
                            visible: Store.dockShowUtils || dockWin.isMediaPlaying
                            implicitWidth: dockWin.isVertical ? dockWin.barThickness : (pod3Row.implicitWidth + 18)
                            implicitHeight: dockWin.isVertical ? (pod3Row.implicitHeight + 18) : dockWin.barThickness
                            radius: dockWin.cornerRadius
                            color: dockWin.shellBg
                            border.width: 1
                            border.color: dockWin.shellBorder

                            GridLayout {
                                id: pod3Row
                                anchors.centerIn: parent
                                flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                                rows: dockWin.isVertical ? -1 : 1
                                columns: dockWin.isVertical ? 1 : -1
                                rowSpacing: 6
                                columnSpacing: 6

                                // Mini live media play/pause with Cava glow when playing
                                DockUtilBtn {
                                    visible: dockWin.activePlayer !== null
                                    iconText: dockWin.isMediaPlaying ? "󰏤" : "󰐊"
                                    tipText: dockWin.activePlayer?.trackTitle || "Media Play/Pause"
                                    activeState: dockWin.isMediaPlaying
                                    accentColor: Colors.tertiary
                                    onTriggered: dockWin.activePlayer?.togglePlaying()
                                }

                                DockUtilBtn {
                                    visible: Store.dockShowUtils
                                    iconText: "󰸉"
                                    tipText: "Wallpaper Studio"
                                    activeState: Store.wallpaperOpen
                                    onTriggered: Store.toggleWallpaper()
                                }

                                DockUtilBtn {
                                    visible: Store.dockShowUtils
                                    iconText: "󱂬"
                                    tipText: "Dock Studio (Chuột phải đổi kiểu nhanh)"
                                    activeState: Store.dockStudioOpen
                                    accentColor: Colors.tertiary
                                    onTriggered: mouse => {
                                        if (mouse.button === Qt.RightButton) Store.cycleDockStyle()
                                        else Store.toggleDockStudio()
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PRESET 5: FULL-WIDTH MODERN GLASS TASKBAR (WIN11 STYLE)
                    // =========================================================
                    Rectangle {
                        id: taskbarShell
                        visible: dockWin.isTaskbar
                        anchors.fill: parent
                        radius: 0
                        color: dockWin.shellBg

                        // Crisp inner edge accent divider
                        Rectangle {
                            anchors.top: dockWin.isBottom ? parent.top : (dockWin.isVertical ? parent.top : undefined)
                            anchors.bottom: dockWin.isVertical ? parent.bottom : undefined
                            anchors.left: dockWin.isBottom ? parent.left : (dockWin.isRight ? parent.left : undefined)
                            anchors.right: dockWin.isBottom ? parent.right : (dockWin.isLeft ? parent.right : undefined)
                            height: dockWin.isBottom ? 1 : parent.height
                            width: dockWin.isVertical ? 1 : parent.width
                            color: Colors.glassBorder
                        }

                        // Left/Top Section: Start + Workspaces
                        GridLayout {
                            anchors.left: dockWin.isBottom ? parent.left : undefined
                            anchors.leftMargin: dockWin.isBottom ? 14 : 0
                            anchors.top: dockWin.isVertical ? parent.top : undefined
                            anchors.topMargin: dockWin.isVertical ? 14 : 0
                            anchors.verticalCenter: dockWin.isBottom ? parent.verticalCenter : undefined
                            anchors.horizontalCenter: dockWin.isVertical ? parent.horizontalCenter : undefined
                            flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                            rows: dockWin.isVertical ? -1 : 1
                            columns: dockWin.isVertical ? 1 : -1
                            rowSpacing: 8
                            columnSpacing: 8

                            DockUtilBtn {
                                iconText: "◆"
                                tipText: "Start / Spotlight"
                                activeState: Store.launcherOpen
                                onTriggered: Store.toggleLauncher()
                            }

                            // Mini Workspace Dots (1..5)
                            GridLayout {
                                visible: !dockWin.isVertical
                                flow: GridLayout.LeftToRight
                                columnSpacing: 5
                                Repeater {
                                    model: 5
                                    delegate: Rectangle {
                                        readonly property int wsId: index + 1
                                        readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                                        width: focused ? 22 : 8
                                        height: 8
                                        radius: 4
                                        color: focused ? Colors.primary : Colors.alpha(Colors.m3onSurfaceVariant, 0.30)
                                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`)
                                        }
                                    }
                                }
                            }
                        }

                        // Center Section: Centered App Strip
                        AppStrip {
                            anchors.centerIn: parent
                        }

                        // Right/Bottom Section: Quick Utils + Clock
                        GridLayout {
                            anchors.right: dockWin.isBottom ? parent.right : undefined
                            anchors.rightMargin: dockWin.isBottom ? 14 : 0
                            anchors.bottom: dockWin.isVertical ? parent.bottom : undefined
                            anchors.bottomMargin: dockWin.isVertical ? 14 : 0
                            anchors.verticalCenter: dockWin.isBottom ? parent.verticalCenter : undefined
                            anchors.horizontalCenter: dockWin.isVertical ? parent.horizontalCenter : undefined
                            flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                            rows: dockWin.isVertical ? -1 : 1
                            columns: dockWin.isVertical ? 1 : -1
                            rowSpacing: 8
                            columnSpacing: 8

                            DockUtilBtn {
                                visible: Store.dockShowUtils
                                iconText: "󰸉"
                                tipText: "Wallpaper Studio"
                                activeState: Store.wallpaperOpen
                                onTriggered: Store.toggleWallpaper()
                            }

                            DockUtilBtn {
                                visible: Store.dockShowUtils
                                iconText: "󱂬"
                                tipText: "Dock Studio (Chuột phải đổi kiểu nhanh)"
                                activeState: Store.dockStudioOpen
                                accentColor: Colors.tertiary
                                onTriggered: mouse => {
                                    if (mouse.button === Qt.RightButton) Store.cycleDockStyle()
                                    else Store.toggleDockStudio()
                                }
                            }

                            DockUtilBtn {
                                visible: Store.dockShowUtils
                                iconText: "󰒓"
                                tipText: "Vela Rice Studio"
                                activeState: Store.settingsOpen
                                onTriggered: Store.toggleSettings()
                            }

                            Rectangle {
                                visible: !dockWin.isVertical
                                width: tbClock.implicitWidth + 18
                                height: 28
                                radius: 14
                                color: Colors.glassHighlight
                                Text {
                                    id: tbClock
                                    anchors.centerIn: parent
                                    text: dockWin.dockClock
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Colors.m3onSurface
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.toggleDeck()
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PRESETS 1, 2, 4, 6: UNIFIED FLOATING CAPSULE
                    //   - prism   (Nocturne Prism — iridescent rim + glass)
                    //   - macos   (macOS Liquid Glass — specular border + wave zoom)
                    //   - cyber   (Cyber Neon HUD — angular neon strips + corners)
                    //   - minimal (Ultra Minimal — featherweight pill)
                    // =========================================================
                    Rectangle {
                        id: unifiedCapsule
                        visible: !dockWin.isIsland && !dockWin.isTaskbar
                        anchors.centerIn: parent
                        implicitWidth: dockWin.isVertical
                            ? dockWin.barThickness
                            : (unifiedFlow.implicitWidth + dockWin.padMain * 2 + (dockWin.isMinimal ? 6 : 14))
                        implicitHeight: dockWin.isVertical
                            ? (unifiedFlow.implicitHeight + dockWin.padMain * 2 + (dockWin.isMinimal ? 6 : 14))
                            : dockWin.barThickness
                        radius: dockWin.cornerRadius
                        color: dockWin.shellBg
                        border.width: dockWin.isCyber ? 1.5 : 1
                        border.color: dockWin.shellBorder

                        Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        // PRISM STYLE: Top Iridescent Specular Shimmer Line
                        Rectangle {
                            visible: dockWin.isPrism && !dockWin.isVertical
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(30, parent.width - dockWin.cornerRadius * 1.8)
                            height: 1.5
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.25; color: Colors.alpha(Colors.primary, 0.70) }
                                GradientStop { position: 0.75; color: Colors.alpha(Colors.tertiary, 0.70) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // MACOS LIQUID GLASS: Soft Inner Glass Rim Reflection
                        Rectangle {
                            visible: dockWin.isMacos
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Math.max(0, parent.radius - 1)
                            color: "transparent"
                            border.width: 1
                            border.color: Colors.alpha(Colors.m3onSurface, 0.12)
                        }

                        // CYBER NEON HUD: Glowing Laser Edge Accent Bar + Corner Ticks
                        Rectangle {
                            visible: dockWin.isCyber
                            anchors.bottom: dockWin.isBottom ? parent.bottom : undefined
                            anchors.left: dockWin.isLeft ? parent.left : (dockWin.isBottom ? parent.left : undefined)
                            anchors.right: dockWin.isRight ? parent.right : (dockWin.isBottom ? parent.right : undefined)
                            anchors.top: dockWin.isVertical ? parent.top : undefined
                            anchors.leftMargin: dockWin.isBottom ? 16 : 0
                            anchors.rightMargin: dockWin.isBottom ? 16 : 0
                            anchors.topMargin: dockWin.isVertical ? 16 : 0
                            anchors.bottomMargin: dockWin.isVertical ? 16 : 0
                            height: dockWin.isBottom ? 2 : undefined
                            width: dockWin.isVertical ? 2 : undefined
                            gradient: Gradient {
                                orientation: dockWin.isVertical ? Gradient.Vertical : Gradient.Horizontal
                                GradientStop { position: 0.0; color: Colors.primary }
                                GradientStop { position: 0.5; color: Colors.tertiary }
                                GradientStop { position: 1.0; color: Colors.primary }
                            }
                        }

                        // AURA STYLE: Ambient Soft Expressive Glow Halo Border
                        Rectangle {
                            visible: dockWin.isAura
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Math.max(0, parent.radius - 2)
                            color: "transparent"
                            border.width: 1.5
                            border.color: Colors.alpha(Colors.tertiary, 0.28)
                        }

                        // Main Capsule Contents
                        GridLayout {
                            id: unifiedFlow
                            anchors.centerIn: parent
                            flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                            rows: dockWin.isVertical ? -1 : 1
                            columns: dockWin.isVertical ? 1 : -1
                            rowSpacing: dockWin.isMinimal ? 6 : 9
                            columnSpacing: dockWin.isMinimal ? 6 : 9

                            // ARCH TILING STRIP: Compact Workspace Switcher Pills (1..5)
                            GridLayout {
                                visible: dockWin.isArchbar
                                Layout.alignment: Qt.AlignCenter
                                flow: dockWin.isVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                                rows: dockWin.isVertical ? -1 : 1
                                columns: dockWin.isVertical ? 1 : -1
                                rowSpacing: 4
                                columnSpacing: 4

                                Repeater {
                                    model: 5
                                    delegate: Rectangle {
                                        readonly property int wsId: index + 1
                                        readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                                        width: focused ? 24 : 20
                                        height: 20
                                        radius: 6
                                        color: focused ? Colors.primary : Colors.glassHighlight
                                        border.width: 1
                                        border.color: focused ? Colors.primary : Colors.glassBorderSubtle
                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: String(wsId)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.bold: focused
                                            color: focused ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`)
                                        }
                                    }
                                }
                            }

                            // Optional Launcher Trigger at start (except Minimal & Archbar)
                            DockUtilBtn {
                                visible: Store.dockShowUtils && !dockWin.isMinimal && !dockWin.isArchbar
                                iconText: "◆"
                                tipText: "App Launcher (Super+Space)"
                                activeState: Store.launcherOpen
                                onTriggered: Store.toggleLauncher()
                            }

                            // Subtle Separator
                            Rectangle {
                                visible: (Store.dockShowUtils && !dockWin.isMinimal) || dockWin.isArchbar
                                Layout.alignment: Qt.AlignCenter
                                width: dockWin.isVertical ? Math.round(dockWin.iconBase * 0.55) : 1
                                height: dockWin.isVertical ? 1 : Math.round(dockWin.iconBase * 0.55)
                                color: dockWin.isCyber ? Colors.alpha(Colors.primary, 0.40) : Colors.glassBorderSubtle
                            }

                            // Core Pinned + Running Apps Strip
                            AppStrip {}

                            // Trailing Separator
                            Rectangle {
                                visible: Store.dockShowUtils
                                Layout.alignment: Qt.AlignCenter
                                width: dockWin.isVertical ? Math.round(dockWin.iconBase * 0.55) : 1
                                height: dockWin.isVertical ? 1 : Math.round(dockWin.iconBase * 0.55)
                                color: dockWin.isCyber ? Colors.alpha(Colors.primary, 0.40) : Colors.glassBorderSubtle
                            }

                            // Quick Utilities at end
                            DockUtilBtn {
                                visible: Store.dockShowUtils && !dockWin.isMinimal
                                iconText: "󰸉"
                                tipText: "Wallpaper Studio"
                                activeState: Store.wallpaperOpen
                                onTriggered: Store.toggleWallpaper()
                            }

                            DockUtilBtn {
                                visible: Store.dockShowUtils
                                iconText: "󱂬"
                                tipText: "Dock Studio · Chuột phải đổi kiểu nhanh"
                                activeState: Store.dockStudioOpen
                                accentColor: Colors.tertiary
                                onTriggered: mouse => {
                                    if (mouse.button === Qt.RightButton) Store.cycleDockStyle()
                                    else Store.toggleDockStudio()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

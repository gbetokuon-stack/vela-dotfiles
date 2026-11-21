import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: launcher
    property real openAnim: Store.launcherOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.launcherOpen ? 260 : 160
            easing.type: Store.launcherOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.launcherOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property string filterTab: "all" // "all" | "pinned" | "system"
    property bool runOnNvidia: false
    property int selectedIndex: 0

    // Spotlight Quick Calculator ("= 144 * 1.5") & Quick Shell ("> cmd")
    readonly property bool isCalcMode: query.trim().startsWith("=")
    readonly property bool isShellMode: query.trim().startsWith(">")
    readonly property string calcResult: {
        if (!isCalcMode) return ""
        const expr = query.trim().slice(1).trim()
        if (!expr) return ""
        if (!/^[0-9+\-*/().%\s^]+$/.test(expr)) return ""
        try {
            const safe = expr.replace(/\^/g, "**")
            const val = Function(`"use strict"; return (${safe})`)()
            if (typeof val === "number" && isFinite(val)) {
                return Number.isInteger(val) ? String(val) : String(Math.round(val * 100000) / 100000)
            }
        } catch (e) {}
        return ""
    }

    Connections {
        target: Store
        function onLauncherOpenChanged() {
            if (Store.launcherOpen) {
                launcher.query = ""
                launcher.selectedIndex = 0
                searchInput.text = ""
                searchInput.forceActiveFocus()
            }
        }
    }

    readonly property var filteredApps: {
        if (isCalcMode || isShellMode) return []
        const q = query.trim().toLowerCase()
        const list = Store.apps || []
        const out = []
        for (let i = 0; i < list.length; i++) {
            const a = list[i]
            if (filterTab === "pinned" && !a.pinned) continue
            if (filterTab === "system" && !(a.categories || "").toLowerCase().includes("system") && !(a.categories || "").toLowerCase().includes("settings")) continue
            if (q.length > 0) {
                const hay = ((a.name || "") + " " + (a.desc || "") + " " + (a.exec || "")).toLowerCase()
                if (!hay.includes(q)) continue
            }
            out.push(a)
        }
        return out
    }

    function launchApp(app, forceNvidia) {
        if (!app) return
        Store.launcherOpen = false
        Store.recordAppLaunch(app.id)
        const useNv = forceNvidia || runOnNvidia
        const cmd = useNv ? `prime-run ${app.exec}` : app.exec
        Store.runCmd(cmd)
    }

    function executeSpotlightAction() {
        if (isCalcMode && calcResult.length > 0) {
            Store.runCmd(`printf '%s' "${calcResult}" | wl-copy && notify-send -a "Vela Spotlight" "Copied Result" "${calcResult}"`)
            Store.launcherOpen = false
            return
        }
        if (isShellMode) {
            const cmd = query.trim().slice(1).trim()
            if (cmd.length > 0) {
                Store.launcherOpen = false
                Store.runCmd(cmd)
            }
            return
        }
        if (filteredApps.length > 0) {
            launchApp(filteredApps[selectedIndex], false)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Store.launcherOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 740
        height: 560
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: launcher.openAnim
        scale: 0.93 + 0.07 * launcher.openAnim
        transform: Translate { y: (1.0 - launcher.openAnim) * 14 }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            // =================================================================
            // 1. SPOTLIGHT SEARCH BAR (= calc · > shell · app search)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 25
                color: Colors.glassCard
                border.width: searchInput.activeFocus ? 2 : 1
                border.color: searchInput.activeFocus ? Colors.primary : Colors.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        text: launcher.isCalcMode ? "󰃬" : (launcher.isShellMode ? "󰆍" : "󰍉")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: launcher.isCalcMode ? Colors.tertiary : Colors.primary
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: "Inter"
                        font.pixelSize: 14
                        color: Colors.m3onSurface
                        clip: true
                        focus: true

                        onTextChanged: {
                            launcher.query = text
                            launcher.selectedIndex = 0
                        }

                        Keys.onEscapePressed: Store.launcherOpen = false
                        Keys.onRightPressed: {
                            if (launcher.selectedIndex + 1 < launcher.filteredApps.length) {
                                launcher.selectedIndex += 1
                                appGrid.positionViewAtIndex(launcher.selectedIndex, GridView.Contain)
                            }
                        }
                        Keys.onLeftPressed: {
                            if (launcher.selectedIndex > 0) {
                                launcher.selectedIndex -= 1
                                appGrid.positionViewAtIndex(launcher.selectedIndex, GridView.Contain)
                            }
                        }
                        Keys.onDownPressed: {
                            const next = Math.min(launcher.filteredApps.length - 1, launcher.selectedIndex + 3)
                            if (next >= 0) {
                                launcher.selectedIndex = next
                                appGrid.positionViewAtIndex(launcher.selectedIndex, GridView.Contain)
                            }
                        }
                        Keys.onUpPressed: {
                            if (launcher.selectedIndex >= 3) {
                                launcher.selectedIndex -= 3
                                appGrid.positionViewAtIndex(launcher.selectedIndex, GridView.Contain)
                            }
                        }
                        Keys.onReturnPressed: launcher.executeSpotlightAction()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: parent.text.length === 0
                            text: "Tìm app · gõ '= 144*2' để tính nhanh · gõ '> cmd' để chạy lệnh"
                            font.family: "Inter"
                            font.pixelSize: 13
                            color: Colors.m3onSurfaceVariant
                        }
                    }

                    Text {
                        visible: searchInput.text.length > 0
                        text: "✕"
                        font.pixelSize: 13
                        color: Colors.m3onSurfaceVariant
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // Spotlight Instant Calculator / Shell Result Banner
            Rectangle {
                visible: launcher.isCalcMode || launcher.isShellMode
                Layout.fillWidth: true
                height: 76
                radius: 20
                color: Colors.alpha(Colors.primary, 0.16)
                border.width: 1.5
                border.color: Colors.primary

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                        width: 44; height: 44; radius: 14
                        color: Colors.primary
                        Text {
                            anchors.centerIn: parent
                            text: launcher.isCalcMode ? "󰃬" : "󰆍"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                            color: Colors.m3onPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: launcher.isCalcMode
                                ? (launcher.calcResult.length > 0 ? `= ${launcher.calcResult}` : "Nhập phép tính (vd: = (1920/16)*9)")
                                : (launcher.query.trim().slice(1).trim() || "Nhập lệnh shell để thực thi...")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            font.bold: true
                            color: Colors.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: launcher.isCalcMode ? "Nhấn Enter để sao chép kết quả vào Clipboard" : "Nhấn Enter để chạy lệnh ngay"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: Colors.m3onSurfaceVariant
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcher.executeSpotlightAction()
                }
            }

            // =================================================================
            // 2. FILTER TABS & RTX 4050 OFFLOAD SWITCH
            // =================================================================
            RowLayout {
                visible: !launcher.isCalcMode && !launcher.isShellMode
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "all",    label: "󰕰  Tất cả App" },
                        { id: "pinned", label: "󰐃  Ghim (Pinned)" },
                        { id: "system", label: "󰒓  Hệ thống & Rice" }
                    ]
                    delegate: Rectangle {
                        readonly property bool active: launcher.filterTab === modelData.id
                        height: 30
                        width: tabTxt.implicitWidth + 24
                        radius: 15
                        color: active ? Colors.primary : Colors.glassCard
                        border.width: 1
                        border.color: active ? Colors.primary : Colors.glassBorderSubtle

                        Text {
                            id: tabTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: active ? Font.Bold : Font.Medium
                            color: active ? Colors.m3onPrimary : Colors.m3onSurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcher.filterTab = modelData.id
                                launcher.selectedIndex = 0
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 30
                    width: nvRow.implicitWidth + 20
                    radius: 15
                    color: launcher.runOnNvidia ? Colors.alpha(Colors.tertiary, 0.28) : Colors.glassCard
                    border.width: 1
                    border.color: launcher.runOnNvidia ? Colors.tertiary : Colors.glassBorderSubtle

                    Row {
                        id: nvRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰢮"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: launcher.runOnNvidia ? Colors.tertiary : Colors.m3onSurfaceVariant
                        }
                        Text {
                            text: launcher.runOnNvidia ? "Chạy bằng RTX 4050: BẬT" : "Chạy bằng RTX 4050"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: launcher.runOnNvidia ? Font.Bold : Font.Medium
                            color: launcher.runOnNvidia ? Colors.tertiary : Colors.m3onSurfaceVariant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.runOnNvidia = !launcher.runOnNvidia
                    }
                }
            }

            // =================================================================
            // 3. APP GRID WITH REAL SYSTEM ICONS + FRECENCY ORDER
            // =================================================================
            GridView {
                id: appGrid
                visible: !launcher.isCalcMode && !launcher.isShellMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 3
                cellHeight: 74
                clip: true
                model: launcher.filteredApps

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight
                    readonly property bool isSel: index === launcher.selectedIndex
                    readonly property string resolvedIcon: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 16
                        color: isSel || itemHover.containsMouse
                            ? Colors.alpha(Colors.primary, 0.22)
                            : Colors.glassCard
                        border.width: isSel ? 1.5 : 1
                        border.color: isSel || itemHover.containsMouse
                            ? Colors.primary
                            : Colors.glassBorderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 13
                                color: resolvedIcon.length > 0
                                    ? (isSel ? Colors.alpha(Colors.primary, 0.28) : Colors.glassHighlight)
                                    : (isSel ? Colors.primary : Colors.glassHighlight)

                                IconImage {
                                    visible: resolvedIcon.length > 0
                                    anchors.centerIn: parent
                                    implicitSize: 28
                                    source: resolvedIcon
                                    mipmap: true
                                    asynchronous: true
                                }

                                Text {
                                    visible: resolvedIcon.length === 0
                                    anchors.centerIn: parent
                                    text: modelData.glyph || "󰣆"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 20
                                    color: isSel ? Colors.m3onPrimary : Colors.primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.name
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Colors.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.desc
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: Colors.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onEntered: launcher.selectedIndex = index
                            onClicked: mouse => {
                                launcher.launchApp(modelData, mouse.button === Qt.RightButton)
                            }
                        }
                    }
                }
            }

            Item {
                visible: launcher.isCalcMode || launcher.isShellMode
                Layout.fillHeight: true
            }

            // =================================================================
            // 4. START MENU FOOTER DOCK
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: Colors.primary
                        Text { anchors.centerIn: parent; text: "◆"; font.pixelSize: 14; color: Colors.m3onPrimary }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "cuongacoustic  ·  Acoustic Studio"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Colors.m3onSurface
                        }
                        Text {
                            text: `GPU: ${Store.gpuDriver === "nouveau" ? "RTX 4050 (Nouveau)" : "RTX 4050 (" + Store.gpuState + ")"}`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.primary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Keybinds Cheatsheet
                    Rectangle {
                        height: 32; width: kbRow.implicitWidth + 16; radius: 16
                        color: Colors.glassHighlight
                        Row {
                            id: kbRow; anchors.centerIn: parent; spacing: 5
                            Text { text: "󰌌"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: Colors.secondary }
                            Text { text: "Phím tắt"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleCheatsheet() }
                    }

                    // Random Wallpaper
                    Rectangle {
                        height: 32; width: randRow.implicitWidth + 16; radius: 16
                        color: Colors.glassHighlight
                        Row {
                            id: randRow; anchors.centerIn: parent; spacing: 5
                            Text { text: "󰒝"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: Colors.primary }
                            Text { text: "Random"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurface }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomWallpaper() }
                    }

                    // Settings Studio
                    Rectangle {
                        height: 32; width: setRow.implicitWidth + 16; radius: 16
                        color: Colors.alpha(Colors.primary, 0.20)
                        Row {
                            id: setRow; anchors.centerIn: parent; spacing: 5
                            Text { text: "󰒓"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: Colors.primary }
                            Text { text: "Rice Studio"; font.family: "Inter"; font.pixelSize: 11; font.bold: true; color: Colors.primary }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleSettings() }
                    }

                    // Lock
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: Colors.glassHighlight
                        Text { anchors.centerIn: parent; text: "󰌾"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Colors.m3onSurface }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Store.launcherOpen = false; Store.runCmd("hyprlock") } }
                    }

                    // Power
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: Colors.alpha(Colors.error, 0.22)
                        Text { anchors.centerIn: parent; text: "󰐥"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Colors.error }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.togglePower() }
                    }
                }
            }
        }
    }
}

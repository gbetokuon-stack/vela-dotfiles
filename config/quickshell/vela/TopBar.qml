import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Widgets

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 10
        left: 14
        right: 14
    }
    implicitHeight: 42
    color: "transparent"

    WlrLayershell.namespace: "vela-bar"
    WlrLayershell.layer: WlrLayer.Top

    property string clockTime: Qt.formatDateTime(new Date(), "HH:mm")
    property string clockDate: Qt.formatDateTime(new Date(), "ddd · dd MMM")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date()
            bar.clockTime = Qt.formatDateTime(now, "HH:mm")
            bar.clockDate = Qt.formatDateTime(now, "ddd · dd MMM")
        }
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

    Item {
        anchors.fill: parent

        // =====================================================================
        // LEFT ISLAND: Start & Search Button + Workspaces + Active Title
        // =====================================================================
        Rectangle {
            id: leftIsland
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            width: leftRow.implicitWidth + 18
            radius: 20
            color: Colors.glassDeep
            border.width: 1
            border.color: Colors.glassBorder

            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }

            RowLayout {
                id: leftRow
                anchors.centerIn: parent
                spacing: 8

                // Start / Spotlight Pill
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: startRow.implicitWidth + 18
                    height: 28
                    radius: 14
                    color: Store.launcherOpen ? Colors.primary : (prismHover.containsMouse ? Colors.glassCard : Colors.glassHighlight)
                    Behavior on color { ColorAnimation { duration: 160 } }

                    Row {
                        id: startRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "◆"
                            font.pixelSize: 13
                            font.bold: true
                            color: Store.launcherOpen ? Colors.m3onPrimary : Colors.primary
                        }
                        Text {
                            text: "󰍉 Apps"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Store.launcherOpen ? Colors.m3onPrimary : Colors.m3onSurface
                        }
                    }

                    MouseArea {
                        id: prismHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleLauncher()
                    }
                }

                Rectangle {
                    width: 1
                    height: 16
                    color: Colors.glassBorderSubtle
                }

                // Morphing Pill Workspaces (1..6)
                Row {
                    spacing: 6
                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            readonly property int wsId: index + 1
                            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
                            readonly property bool isOccupied: {
                                const list = Hyprland.workspaces.values
                                for (let i = 0; i < list.length; i++) {
                                    if (list[i].id === wsId) return true
                                }
                                return false
                            }

                            height: 22
                            width: isFocused ? 34 : (isOccupied ? 20 : 12)
                            radius: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: isFocused
                                ? Colors.primary
                                : (isOccupied ? Colors.alpha(Colors.secondary, 0.32) : Colors.alpha(Colors.m3onSurfaceVariant, 0.22))

                            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                visible: parent.isFocused || parent.isOccupied
                                text: parent.wsId
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: parent.isFocused
                                color: parent.isFocused ? Colors.m3onPrimary : Colors.m3onSurface
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.wsId} })`)
                            }
                        }
                    }
                }

                // Active Window Title Pill
                Text {
                    readonly property string title: Hyprland.activeToplevel?.title ?? ""
                    visible: title.length > 0
                    text: title.length > 22 ? title.slice(0, 22) + "…" : title
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Colors.m3onSurfaceVariant
                    leftPadding: 4
                    rightPadding: 4
                }
            }
        }

        // =====================================================================
        // CENTER ISLAND: Clock + Live Cava Spectrum + Media Controls
        // =====================================================================
        Rectangle {
            id: centerIsland
            anchors.centerIn: parent
            height: 40
            width: centerRow.implicitWidth + (centerHover.containsMouse || Store.deckOpen ? 36 : 26)
            radius: 20
            color: Store.deckOpen ? Colors.alpha(Colors.primary, 0.22) : Colors.glassDeep
            border.width: 1
            border.color: (centerHover.containsMouse || Store.deckOpen) ? Colors.alpha(Colors.primary, 0.65) : Colors.glassBorder
            scale: centerHover.pressed ? 0.97 : (centerHover.containsMouse ? 1.02 : 1.0)

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            MouseArea {
                id: centerHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        Store.randomWallpaper()
                    } else {
                        Store.toggleDeck()
                    }
                }
            }

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: bar.clockTime
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Colors.m3onSurface
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Colors.primary
                }

                Text {
                    text: bar.clockDate
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Colors.m3onSurfaceVariant
                }

                RowLayout {
                    visible: bar.activePlayer !== null && (bar.activePlayer.trackTitle ?? "").length > 0
                    spacing: 8

                    Rectangle {
                        width: 1
                        height: 16
                        color: Colors.glassBorderSubtle
                    }

                    // Live Cava 8-Bar Audio Visualizer (when playing)
                    Row {
                        visible: bar.isMediaPlaying
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        height: 16

                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                readonly property int barVal: (Store.cavaBars && Store.cavaBars.length > index) ? Store.cavaBars[index] : 10
                                width: 2.5
                                height: Math.max(3, Math.round(3 + (barVal / 100.0) * 13))
                                radius: 1.5
                                anchors.bottom: parent.bottom
                                color: index % 2 === 0 ? Colors.primary : Colors.tertiary
                                Behavior on height { NumberAnimation { duration: 55; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    Text {
                        visible: !bar.isMediaPlaying
                        text: "󰏤"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: Colors.tertiary
                    }

                    Text {
                        readonly property string song: bar.activePlayer?.trackTitle ?? ""
                        text: song.length > 20 ? song.slice(0, 20) + "…" : song
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.m3onSurface
                    }

                    Text {
                        text: bar.isMediaPlaying ? "󰏤" : "󰐊"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: Colors.primary
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.activePlayer?.togglePlaying()
                        }
                    }

                    Text {
                        text: "󰒭"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: Colors.m3onSurfaceVariant
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.activePlayer?.next()
                        }
                    }
                }
            }
        }

        // =====================================================================
        // RIGHT ISLAND: System Tray + Fcitx5 + Quick Tools + GPU + System + Bell
        // =====================================================================
        Rectangle {
            id: rightIsland
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            width: rightRow.implicitWidth + 22
            radius: 20
            color: Colors.glassDeep
            border.width: 1
            border.color: Colors.glassBorder

            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }

            RowLayout {
                id: rightRow
                anchors.centerIn: parent
                spacing: 9

                // Native System Tray Icons (Discord, Steam, OBS, Fcitx5, etc.)
                Row {
                    visible: SystemTray.items.values.length > 0
                    spacing: 6
                    Repeater {
                        model: SystemTray.items.values
                        delegate: Item {
                            required property var modelData
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon
                                mipmap: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                                        const pos = mapToItem(null, width / 2, height)
                                        modelData.display(bar, Math.round(pos.x), Math.round(pos.y))
                                    } else {
                                        modelData.activate()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: SystemTray.items.values.length > 0
                    width: 1
                    height: 15
                    color: Colors.glassBorderSubtle
                }

                // Fcitx5 Vietnamese / English Pill
                Rectangle {
                    visible: Store.imEngine.length > 0
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: imTxt.implicitWidth + 14
                    height: 22
                    radius: 11
                    color: Store.imEngine === "VN" ? Colors.alpha(Colors.primary, 0.24) : Colors.glassHighlight
                    border.width: 1
                    border.color: Store.imEngine === "VN" ? Colors.primary : Colors.glassBorderSubtle

                    Text {
                        id: imTxt
                        anchors.centerIn: parent
                        text: Store.imEngine
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        color: Store.imEngine === "VN" ? Colors.primary : Colors.m3onSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleInputMethod()
                    }
                }

                // Clipboard Vault Trigger
                Text {
                    text: "󰅌"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: Store.clipboardOpen ? Colors.primary : Colors.m3onSurfaceVariant
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleClipboard()
                    }
                }

                // 1-Click Random Wallpaper + Palette
                Text {
                    text: "󰒝"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colors.primary
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.randomWallpaper()
                    }
                }

                // 1-Click Dark / Light Mode Toggle
                Text {
                    text: Store.currentMode === "dark" ? "󰖔" : "󰖨"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Colors.tertiary
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleDarkLight()
                    }
                }

                // Wallpaper Gallery Trigger
                Text {
                    text: "󰸉"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Store.wallpaperOpen ? Colors.primary : Colors.m3onSurfaceVariant
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleWallpaper()
                    }
                }

                // Vela Settings Studio Trigger
                Text {
                    text: "󰒓"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Store.settingsOpen ? Colors.primary : Colors.m3onSurface
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleSettings()
                    }
                }

                // HP Victus Hybrid GPU Indicator
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: gpuLabel.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: Store.gpuDriver === "nouveau"
                        ? Colors.alpha(Colors.error, 0.22)
                        : (Store.gpuState === "Active" ? Colors.alpha(Colors.tertiary, 0.25) : Colors.glassHighlight)
                    border.width: 1
                    border.color: Store.gpuDriver === "nouveau"
                        ? Colors.error
                        : (Store.gpuState === "Active" ? Colors.tertiary : Colors.glassBorderSubtle)

                    Text {
                        id: gpuLabel
                        anchors.centerIn: parent
                        text: Store.gpuDriver === "nouveau"
                            ? (Store.nvidiaPkgInstalled ? (Store.nvidiaModIndexed ? "RTX·Reboot" : "RTX·Fix") : "RTX·Setup")
                            : (Store.gpuState === "Active" ? `RTX ${Store.gpuTemp}°` : "iGPU")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        color: Store.gpuDriver === "nouveau"
                            ? Colors.error
                            : (Store.gpuState === "Active" ? Colors.tertiary : Colors.m3onSurfaceVariant)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleSettings()
                    }
                }

                // Power Profile Badge
                Text {
                    text: Store.profile === "performance" ? "󰓅" : (Store.profile === "power-saver" ? "󰌪" : "󰾅")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Store.profile === "performance" ? Colors.error : (Store.profile === "power-saver" ? Colors.tertiary : Colors.primary)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.cycleProfile()
                    }
                }

                // Volume Indicator
                Item {
                    implicitWidth: volRow.implicitWidth
                    implicitHeight: volRow.implicitHeight
                    Row {
                        id: volRow
                        spacing: 4
                        Text {
                            text: Store.muted || Store.volume === 0
                                ? "󰝟"
                                : (Store.activeSinkIsHeadset ? "󰋋" : (Store.volume > 50 ? "󰕾" : "󰖀"))
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: Store.muted ? Colors.m3onSurfaceVariant : (Store.activeSinkIsHeadset ? Colors.primary : Colors.m3onSurface)
                        }
                        Text {
                            text: Store.muted ? "M" : `${Store.volume}%`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Colors.m3onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        property real wheelAccum: 0
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                Store.cycleAudioSink()
                            } else if (mouse.button === Qt.MiddleButton) {
                                Store.toggleDeck()
                            } else {
                                Store.toggleMute()
                            }
                        }
                        onWheel: wheel => {
                            wheelAccum += wheel.angleDelta.y
                            const stepThreshold = 60
                            const steps = wheelAccum > 0
                                ? Math.floor(wheelAccum / stepThreshold)
                                : Math.ceil(wheelAccum / stepThreshold)
                            if (steps !== 0) {
                                wheelAccum -= steps * stepThreshold
                                Store.adjustVolume(steps)
                                Store.showOsd("volume")
                            }
                        }
                    }
                }

                // Network Icon
                Text {
                    text: Store.netType === "wifi" ? "󰤨" : (Store.netType === "ethernet" ? "󰈀" : "󰤭")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Store.netType === "offline" ? Colors.error : Colors.m3onSurface
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleDeck()
                    }
                }

                // Battery Pill
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: batRow.implicitWidth + 16
                    height: 24
                    radius: 12
                    color: Store.batCap <= 20 && Store.batStatus !== "Charging"
                        ? Colors.alpha(Colors.error, 0.28)
                        : Colors.glassCard

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: Store.batStatus === "Charging" ? "󰂄" : (Store.batCap > 80 ? "󰁹" : (Store.batCap > 50 ? "󰁾" : (Store.batCap > 20 ? "󰁼" : "󰁺")))
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: Store.batStatus === "Charging" ? Colors.primary : (Store.batCap <= 20 ? Colors.error : Colors.m3onSurface)
                        }
                        Text {
                            text: `${Store.batCap}%`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.m3onSurface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleDeck()
                    }
                }

                // Command Deck & Notification Bell Trigger (with Unread Badge)
                Item {
                    width: 28
                    height: 28

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: Store.deckOpen ? Colors.primary : Colors.glassHighlight
                        Text {
                            anchors.centerIn: parent
                            text: Store.dndEnabled ? "󰂛" : "󰂚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: Store.deckOpen ? Colors.m3onPrimary : Colors.primary
                        }
                    }

                    // Unread Notification Count Pill
                    Rectangle {
                        visible: Store.unreadNotifs > 0 && !Store.deckOpen
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: Store.unreadNotifs > 9 ? 16 : 13
                        height: 13
                        radius: 6.5
                        color: Colors.error

                        Text {
                            anchors.centerIn: parent
                            text: Store.unreadNotifs > 9 ? "9+" : String(Store.unreadNotifs)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            font.bold: true
                            color: Colors.m3onError
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.toggleDeck()
                    }
                }
            }
        }
    }
}

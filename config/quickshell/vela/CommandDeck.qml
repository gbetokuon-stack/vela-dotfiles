import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: deck
    property real openAnim: Store.deckOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.deckOpen ? 280 : 170
            easing.type: Store.deckOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.deckOpen || openAnim > 0.005
    anchors {
        top: true
        right: true
    }
    margins {
        top: 60
        right: 14
    }
    implicitWidth: 406
    implicitHeight: Math.min(920, cardContent.implicitHeight + 36)
    color: "transparent"

    WlrLayershell.namespace: "vela-deck"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.deckOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property int playerIdx: 0
    readonly property var allPlayers: Mpris.players.values || []
    readonly property var activePlayer: {
        if (!allPlayers || allPlayers.length === 0) return null
        if (playerIdx >= 0 && playerIdx < allPlayers.length) return allPlayers[playerIdx]
        for (let i = 0; i < allPlayers.length; i++) {
            if (allPlayers[i].playbackState === MprisPlaybackState.Playing) return allPlayers[i]
        }
        return allPlayers[0]
    }
    property real mediaPos: 0
    Timer {
        interval: 1000
        running: Store.deckOpen && deck.activePlayer !== null && deck.activePlayer.playbackState === MprisPlaybackState.Playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (deck.activePlayer) {
                deck.mediaPos = deck.activePlayer.position || 0
            }
        }
    }
    function fmtTime(sec) {
        const s = Math.max(0, Math.floor(sec || 0))
        const m = Math.floor(s / 60)
        const r = s % 60
        return `${m}:${r < 10 ? "0" : ""}${r}`
    }

    // Reusable Bento Toggle Tile
    component BentoToggle: Rectangle {
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        height: 60
        radius: 16
        color: active ? Colors.alpha(Colors.primary, 0.24) : Colors.glassCard
        border.width: 1
        border.color: active ? Colors.alpha(Colors.primary, 0.65) : Colors.glassBorderSubtle

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: active ? Colors.primary : Colors.glassHighlight
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: active ? Colors.m3onPrimary : Colors.m3onSurface
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: label
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Colors.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: sublabel
                    font.family: "Inter"
                    font.pixelSize: 10
                    color: active ? Colors.primary : Colors.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // Reusable Smooth Glass Slider (zero-lag 144Hz drag + smooth scroll + clickable icon)
    component TonalSlider: RowLayout {
        id: sliderRoot
        property string icon: ""
        property int value: 50
        property int maxValue: 100
        property bool muted: false
        property bool iconClickable: false
        signal moved(int val)
        signal iconClicked()

        readonly property real displayRatio: Math.max(0, Math.min(1, value / Math.max(1, maxValue)))

        Layout.fillWidth: true
        spacing: 12

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            Text {
                anchors.centerIn: parent
                text: sliderRoot.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: sliderRoot.muted ? Colors.m3onSurfaceVariant : Colors.primary
            }

            MouseArea {
                anchors.fill: parent
                enabled: sliderRoot.iconClickable
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: sliderRoot.iconClicked()
            }
        }

        Item {
            id: trackWrap
            Layout.fillWidth: true
            height: 28

            Rectangle {
                id: trackBg
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 10
                radius: 5
                color: Colors.glassHighlight

                Rectangle {
                    id: fillBar
                    readonly property real targetWidth: sliderRoot.muted || sliderRoot.displayRatio <= 0
                        ? 0
                        : Math.max(10, parent.width * sliderRoot.displayRatio)
                    width: targetWidth
                    height: parent.height
                    radius: 5
                    opacity: sliderRoot.muted ? 0.35 : 1.0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Behavior on width {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                }
            }

            // Smooth tactile handle pill/thumb (tracks at full refresh rate while dragging)
            Rectangle {
                id: thumb
                width: sliderMouse.pressed ? 18 : (sliderMouse.containsMouse ? 16 : 12)
                height: width
                radius: width / 2
                anchors.verticalCenter: trackBg.verticalCenter
                x: Math.max(0, Math.min(trackBg.width - width, fillBar.width - width / 2))
                color: Colors.m3onPrimary
                border.width: 2
                border.color: sliderRoot.muted ? Colors.m3onSurfaceVariant : Colors.primary
                opacity: sliderMouse.containsMouse || sliderMouse.pressed ? 1.0 : 0.85

                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: sliderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property int lastSentVal: -1
                property real wheelAccum: 0

                function updateFromX(mx) {
                    const ratio = Math.max(0, Math.min(1, mx / Math.max(1, width)))
                    const nextVal = Math.round(ratio * sliderRoot.maxValue)
                    if (nextVal !== lastSentVal) {
                        lastSentVal = nextVal
                        sliderRoot.moved(nextVal)
                    }
                }

                onPressed: mouse => {
                    lastSentVal = -1
                    updateFromX(mouse.x)
                }
                onPositionChanged: mouse => {
                    if (pressed) updateFromX(mouse.x)
                }
                onReleased: lastSentVal = -1
                onWheel: wheel => {
                    wheelAccum += wheel.angleDelta.y
                    const stepThreshold = 60 // 1 mouse detent (120) = 2%, smooth touchpad = 1% steps
                    const steps = wheelAccum > 0
                        ? Math.floor(wheelAccum / stepThreshold)
                        : Math.ceil(wheelAccum / stepThreshold)
                    if (steps !== 0) {
                        wheelAccum -= steps * stepThreshold
                        const nextVal = Math.max(0, Math.min(sliderRoot.maxValue, sliderRoot.value + steps))
                        sliderRoot.moved(nextVal)
                    }
                }
            }
        }

        Text {
            text: sliderRoot.muted ? "M" : `${sliderRoot.value}%`
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: sliderRoot.muted ? Colors.m3onSurfaceVariant : Colors.m3onSurfaceVariant
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: deck.openAnim
        scale: 0.94 + 0.06 * deck.openAnim
        transformOrigin: Item.TopRight
        transform: Translate { y: (1.0 - deck.openAnim) * -12 }

        Keys.onEscapePressed: Store.deckOpen = false

        ColumnLayout {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 14

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "◆"
                        font.pixelSize: 18
                        color: Colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: "Vela Command Deck"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: `Victus 15  ·  Ryzen 7 + RTX 4050`
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                // Quick Lock
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Colors.glassCard
                    Text { anchors.centerIn: parent; text: "󰌾"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Colors.m3onSurface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Store.deckOpen = false; Store.runCmd("hyprlock") } }
                }

                // Quick Power Menu
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Colors.alpha(Colors.error, 0.22)
                    Text { anchors.centerIn: parent; text: "󰐥"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Colors.error }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.togglePower() }
                }
            }

            // 2x3 Quick Toggles Bento Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                BentoToggle {
                    icon: Store.netType === "wifi" ? "󰤨" : (Store.netType === "ethernet" ? "󰈀" : "󰤭")
                    label: "Network"
                    sublabel: Store.netName
                    active: Store.netType !== "offline"
                    onClicked: Store.runCmd("kitty -e iwctl")
                }

                BentoToggle {
                    icon: Store.btOn ? "󰂯" : "󰂲"
                    label: "Bluetooth"
                    sublabel: Store.btOn ? "Powered On" : "Off"
                    active: Store.btOn
                    onClicked: Store.toggleBluetooth()
                }

                BentoToggle {
                    icon: Store.profile === "performance" ? "󰓅" : (Store.profile === "power-saver" ? "󰌪" : "󰾅")
                    label: "Power"
                    sublabel: Store.profile
                    active: Store.profile === "performance"
                    onClicked: Store.cycleProfile()
                }

                BentoToggle {
                    icon: "󰖔"
                    label: "Night Light"
                    sublabel: Store.nightLight ? "4200K Warm" : "Off"
                    active: Store.nightLight
                    onClicked: Store.toggleNightLight()
                }

                BentoToggle {
                    icon: Store.dndEnabled ? "󰂛" : "󰂚"
                    label: "Quiet Mode"
                    sublabel: Store.dndEnabled ? "Silenced" : "Active"
                    active: Store.dndEnabled
                    onClicked: Store.dndEnabled = !Store.dndEnabled
                }

                BentoToggle {
                    icon: "󰊗"
                    label: "Game Mode"
                    sublabel: Store.gameMode ? "144Hz Raw" : "Visual FX"
                    active: Store.gameMode
                    onClicked: Store.toggleGameMode()
                }
            }

            // Brightness & Volume Sliders Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: slidersCol.implicitHeight + 24
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: slidersCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    TonalSlider {
                        icon: "󰃠"
                        value: Store.brightness
                        maxValue: 100
                        onMoved: val => Store.setBrightness(val)
                    }

                    TonalSlider {
                        icon: Store.muted || Store.volume === 0
                            ? "󰝟"
                            : (Store.activeSinkIsHeadset ? "󰋋" : (Store.volume > 50 ? "󰕾" : "󰖀"))
                        value: Store.volume
                        maxValue: 100
                        muted: Store.muted
                        iconClickable: true
                        onIconClicked: Store.toggleMute()
                        onMoved: val => Store.setVolume(val)
                    }

                    // Quick Audio Output Switcher (Loa Laptop / USB Headset / Bluetooth / HDMI)
                    ColumnLayout {
                        visible: Store.audioSinks.length > 0
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "THIẾT BỊ PHÁT"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.bold: true
                                color: Colors.m3onSurfaceVariant
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "󰍜 Mixer"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: Colors.primary
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Store.deckOpen = false
                                        Store.runCmd("pavucontrol")
                                    }
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: Store.audioSinks.length === 2 ? 2 : 1
                            columnSpacing: 8
                            rowSpacing: 6

                            Repeater {
                                model: Store.audioSinks
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isDefault: Store.defaultSink !== null && modelData.id === Store.defaultSink.id
                                    readonly property int sinkVol: modelData.ready && modelData.audio
                                        ? Math.max(0, Math.min(150, Math.round((modelData.audio.volume ?? 0) * 100)))
                                        : 0
                                    readonly property bool sinkMuted: Boolean(modelData.ready && modelData.audio && modelData.audio.muted)

                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 12
                                    color: isDefault ? Colors.alpha(Colors.primary, 0.22) : Colors.glassHighlight
                                    border.width: 1
                                    border.color: isDefault ? Colors.alpha(Colors.primary, 0.70) : Colors.glassBorderSubtle

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 7

                                        Text {
                                            text: sinkMuted ? "󰝟" : Store.sinkIcon(modelData)
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 14
                                            color: isDefault ? Colors.primary : Colors.m3onSurfaceVariant
                                        }

                                        Text {
                                            text: Store.sinkDisplayName(modelData)
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                            font.weight: isDefault ? Font.Bold : Font.Medium
                                            color: isDefault ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: sinkMuted ? "M" : `${sinkVol}%`
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            color: isDefault ? Colors.primary : Colors.m3onSurfaceVariant
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        property real wheelAccum: 0
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                Store.toggleSinkMute(modelData)
                                            } else {
                                                Store.setDefaultSink(modelData)
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
                                                Store.setSinkVolume(modelData, sinkVol + steps)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Per-App PipeWire Audio Mixer (shown automatically when apps play audio)
                    ColumnLayout {
                        visible: Store.audioStreams.length > 0
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 6

                        Text {
                            text: `ÂM LƯỢNG TỪNG ỨNG DỤNG (${Store.audioStreams.length})`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                            color: Colors.tertiary
                        }

                        Repeater {
                            model: Store.audioStreams
                            delegate: RowLayout {
                                required property var modelData
                                readonly property int appVol: modelData.ready && modelData.audio
                                    ? Math.max(0, Math.min(120, Math.round((modelData.audio.volume ?? 0) * 100)))
                                    : 0
                                readonly property bool appMuted: Boolean(modelData.ready && modelData.audio && modelData.audio.muted)

                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: appMuted ? "󰝟" : Store.streamIcon(modelData)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: appMuted ? Colors.m3onSurfaceVariant : Colors.tertiary
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.toggleSinkMute(modelData)
                                    }
                                }

                                Text {
                                    text: Store.streamDisplayName(modelData)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Colors.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.preferredWidth: 92
                                }

                                Item {
                                    Layout.fillWidth: true
                                    height: 20

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 6
                                        radius: 3
                                        color: Colors.glassHighlight

                                        Rectangle {
                                            readonly property real ratio: appMuted ? 0 : Math.max(0, Math.min(1, appVol / 100))
                                            width: ratio <= 0 ? 0 : Math.max(6, parent.width * ratio)
                                            height: parent.height
                                            radius: 3
                                            color: Colors.tertiary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        function setX(mx) {
                                            const r = Math.max(0, Math.min(1, mx / Math.max(1, width)))
                                            Store.setSinkVolume(modelData, Math.round(r * 100))
                                        }
                                        onPressed: m => setX(m.x)
                                        onPositionChanged: m => { if (pressed) setX(m.x) }
                                    }
                                }

                                Text {
                                    text: appMuted ? "M" : `${appVol}%`
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: Colors.m3onSurfaceVariant
                                    Layout.preferredWidth: 32
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }

            // Victus Hardware Telemetry Bento Card (AMD Ryzen 7 + NVIDIA RTX 4050 + RAM)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: telemetryCol.implicitHeight + 24
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: telemetryCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "HARDWARE TELEMETRY"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.m3onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Store.batWatts > 0 ? `${Store.batWatts}W · ${Store.batCap}%` : `${Store.batCap}% ${Store.batStatus}`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Colors.primary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // AMD Ryzen 7 Tile
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: 12
                            color: Colors.glassHighlight
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "RYZEN 7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Colors.m3onSurfaceVariant }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: `${Store.cpuPct}%`; font.family: "Inter"; font.pixelSize: 16; font.bold: true; color: Colors.primary }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: `${Store.cpuTemp}°C`; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: Colors.m3onSurfaceVariant }
                            }
                        }

                        // NVIDIA RTX 4050 Tile
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: 12
                            color: Colors.glassHighlight
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "RTX 4050"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Colors.m3onSurfaceVariant }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Store.gpuState === "Active" ? `${Store.gpuUtil}%` : Store.gpuState
                                    font.family: "Inter"
                                    font.pixelSize: Store.gpuState === "Active" ? 16 : 13
                                    font.bold: true
                                    color: Store.gpuState === "Active" ? Colors.tertiary : Colors.m3onSurface
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Store.gpuState === "Active" ? `${Store.gpuTemp}°C · ${Store.gpuVram}` : "0W Idle"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: Colors.m3onSurfaceVariant
                                }
                            }
                        }

                        // Memory Tile
                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: 12
                            color: Colors.glassHighlight
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "MEMORY"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Colors.m3onSurfaceVariant }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: `${Store.memPct}%`; font.family: "Inter"; font.pixelSize: 16; font.bold: true; color: Colors.secondary }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: `${Store.memUsedGb}/${Store.memTotalGb}G`; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: Colors.m3onSurfaceVariant }
                            }
                        }
                    }
                }
            }

            // Now Playing Card with Live Cava Spectrum & Seek Progress Bar
            Rectangle {
                visible: deck.activePlayer !== null && (deck.activePlayer.trackTitle ?? "").length > 0
                Layout.fillWidth: true
                implicitHeight: mediaCol.implicitHeight + 24
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.alpha(Colors.tertiary, 0.35)

                ColumnLayout {
                    id: mediaCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: Colors.glassHighlight
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: deck.activePlayer?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                visible: !(deck.activePlayer?.trackArtUrl)
                                anchors.centerIn: parent
                                text: "󰎈"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: Colors.tertiary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: deck.activePlayer?.trackTitle ?? "No Media"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.bold: true
                                color: Colors.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: deck.activePlayer?.trackArtist ?? ""
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: Colors.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Row {
                            spacing: 8
                            Text {
                                visible: deck.allPlayers.length > 1
                                text: "󰓡"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: Colors.tertiary
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: deck.playerIdx = (deck.playerIdx + 1) % deck.allPlayers.length
                                }
                            }
                            Text {
                                text: "󰒮"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: Colors.m3onSurfaceVariant
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: deck.activePlayer?.previous() }
                            }
                            Text {
                                text: deck.activePlayer?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: Colors.primary
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: deck.activePlayer?.togglePlaying() }
                            }
                            Text {
                                text: "󰒭"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: Colors.m3onSurfaceVariant
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: deck.activePlayer?.next() }
                            }
                        }
                    }

                    // Live 12-Bar Cava Audio Visualizer
                    Row {
                        visible: deck.activePlayer?.playbackState === MprisPlaybackState.Playing
                        Layout.fillWidth: true
                        height: 20
                        spacing: 4

                        Repeater {
                            model: 12
                            delegate: Rectangle {
                                readonly property int bv: (Store.cavaBars && Store.cavaBars.length > index) ? Store.cavaBars[index] : 8
                                width: Math.max(4, (mediaCol.width - 44) / 12)
                                height: Math.max(3, Math.round(3 + (bv / 100.0) * 17))
                                radius: 2
                                anchors.bottom: parent.bottom
                                color: index < 4 ? Colors.secondary : (index < 8 ? Colors.primary : Colors.tertiary)
                                Behavior on height { NumberAnimation { duration: 55; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    // MPRIS Timeline / Seek Bar
                    RowLayout {
                        visible: (deck.activePlayer?.length ?? 0) > 0
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: deck.fmtTime(deck.mediaPos)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Colors.m3onSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 14

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 5
                                radius: 2.5
                                color: Colors.glassHighlight

                                Rectangle {
                                    readonly property real ratio: Math.max(0, Math.min(1, deck.mediaPos / Math.max(1, deck.activePlayer?.length ?? 1)))
                                    width: parent.width * ratio
                                    height: parent.height
                                    radius: 2.5
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Colors.primary }
                                        GradientStop { position: 1.0; color: Colors.tertiary }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (deck.activePlayer && deck.activePlayer.canSeek && deck.activePlayer.length > 0) {
                                        const target = Math.max(0, Math.min(1, mouse.x / Math.max(1, width))) * deck.activePlayer.length
                                        deck.activePlayer.position = target
                                        deck.mediaPos = target
                                    }
                                }
                            }
                        }

                        Text {
                            text: deck.fmtTime(deck.activePlayer?.length ?? 0)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            color: Colors.m3onSurfaceVariant
                        }
                    }
                }
            }

            // Notification History Center Card
            Rectangle {
                visible: (Store.notifHistory || []).length > 0
                Layout.fillWidth: true
                implicitHeight: histCol.implicitHeight + 22
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: histCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: `󰂚  THÔNG BÁO GẦN ĐÂY (${(Store.notifHistory || []).length})`
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                            color: Colors.primary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Xóa hết"
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Colors.error
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Store.clearNotifHistory()
                            }
                        }
                    }

                    Repeater {
                        model: (Store.notifHistory || []).slice(0, 3)
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: nhRow.implicitHeight + 12
                            radius: 12
                            color: Colors.glassHighlight

                            RowLayout {
                                id: nhRow
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    width: 3
                                    Layout.fillHeight: true
                                    radius: 1.5
                                    color: modelData.critical ? Colors.error : Colors.primary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.summary
                                            font.family: "Inter"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            color: Colors.m3onSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.time
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 9
                                            color: Colors.m3onSurfaceVariant
                                        }
                                    }
                                    Text {
                                        visible: (modelData.body || "").length > 0
                                        text: modelData.body
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: Colors.m3onSurfaceVariant
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: "✕"
                                    font.pixelSize: 10
                                    color: Colors.m3onSurfaceVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.removeHistoryItem(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Randomizer + Dark/Light + Rice Studio Action Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 14
                    color: Colors.alpha(Colors.primary, 0.18)
                    border.width: 1
                    border.color: Colors.alpha(Colors.primary, 0.40)
                    Text {
                        anchors.centerIn: parent
                        text: "󰒝 Random Ảnh"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Colors.primary
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomWallpaper() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 14
                    color: Colors.alpha(Colors.tertiary, 0.18)
                    border.width: 1
                    border.color: Colors.alpha(Colors.tertiary, 0.40)
                    Text {
                        anchors.centerIn: parent
                        text: Store.currentMode === "dark" ? "󰖔 Dark Mode" : "󰖨 Light Mode"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Colors.tertiary
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleDarkLight() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 14
                    color: Colors.glassCard
                    border.width: 1
                    border.color: Colors.glassBorderSubtle
                    Text {
                        anchors.centerIn: parent
                        text: "󰸉 Kho Ảnh"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Colors.m3onSurface
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleWallpaper() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 14
                color: Store.gpuDriver === "nouveau" ? Colors.alpha(Colors.error, 0.18) : Colors.alpha(Colors.primary, 0.16)
                border.width: 1
                border.color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.alpha(Colors.primary, 0.40)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    Text {
                        text: Store.gpuDriver === "nouveau"
                            ? "󰒓  Tùy chỉnh Rice, Blur, Animation & Cài Driver RTX 4050"
                            : "󰒓  Vela System & Rice Studio (Blur · Animation · 144Hz)"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Super + I"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Store.toggleSettings()
                }
            }
        }
    }
}

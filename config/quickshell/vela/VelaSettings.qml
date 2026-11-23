import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: settingsWin
    property real openAnim: Store.settingsOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.settingsOpen ? 260 : 160
            easing.type: Store.settingsOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.settingsOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.settingsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var schemes: [
        { id: "scheme-tonal-spot",  label: "Tonal Spot" },
        { id: "scheme-expressive",  label: "Expressive" },
        { id: "scheme-fidelity",    label: "Fidelity" },
        { id: "scheme-vibrant",     label: "Vibrant" },
        { id: "scheme-fruit-salad", label: "Fruit Salad" },
        { id: "scheme-rainbow",     label: "Rainbow" },
        { id: "scheme-monochrome",  label: "Monochrome" }
    ]

    readonly property var animPresets: [
        { id: "spring", label: "󰘷  Spring 144Hz", desc: "Lò xo mượt kiểu end-4" },
        { id: "snappy", label: "󰓅  Ultra Snappy", desc: "Nhanh, phản hồi tức thì" },
        { id: "smooth", label: "🌊  Smooth Silk",  desc: "Chuyển động điện ảnh" },
        { id: "off",    label: "󰅙  Tắt Animation", desc: "0ms Raw Performance" }
    ]

    component SettingSlider: RowLayout {
        property string label: ""
        property int value: 0
        property int minValue: 0
        property int maxValue: 100
        property string suffix: ""
        signal changed(int v)

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: label
            font.family: "Inter"
            font.pixelSize: 12
            color: Colors.m3onSurface
            Layout.preferredWidth: 150
        }

        Item {
            Layout.fillWidth: true
            height: 24

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: Colors.glassHighlight

                Rectangle {
                    readonly property real ratio: Math.max(0, Math.min(1, (value - minValue) / Math.max(1, maxValue - minValue)))
                    width: Math.max(8, parent.width * ratio)
                    height: parent.height
                    radius: 4
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
                function applyX(mx) {
                    const r = Math.max(0, Math.min(1, mx / width))
                    const v = Math.round(minValue + r * (maxValue - minValue))
                    changed(v)
                }
                onPressed: m => applyX(m.x)
                onPositionChanged: m => { if (pressed) applyX(m.x) }
            }
        }

        Text {
            text: `${value}${suffix}`
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            color: Colors.primary
            Layout.preferredWidth: 46
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Store.settingsOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 800
        height: 690
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: settingsWin.openAnim
        scale: 0.93 + 0.07 * settingsWin.openAnim
        transform: Translate { y: (1.0 - settingsWin.openAnim) * 14 }

        focus: Store.settingsOpen
        Keys.onEscapePressed: Store.settingsOpen = false
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 40; height: 40; radius: 20
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text { anchors.centerIn: parent; text: "󰒓"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: Colors.m3onPrimary }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Vela System & Rice Studio"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: "Tùy chỉnh trực tiếp Âm thanh (2 loa), Animation, Blur, Chủ đề Màu, Hiệu năng & Driver RTX 4050"
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: resetTxt.implicitWidth + 24
                    height: 32; radius: 16
                    color: Colors.glassCard
                    border.width: 1; border.color: Colors.glassBorderSubtle
                    Text { id: resetTxt; anchors.centerIn: parent; text: "↺ Mặc định"; font.family: "Inter"; font.pixelSize: 11; color: Colors.m3onSurfaceVariant }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.resetTuning() }
                }

                Rectangle {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    width: 32; height: 32; radius: 16; color: Colors.glassCard
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 13; color: Colors.m3onSurface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.settingsOpen = false }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: settingsBody.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    id: settingsBody
                    width: parent.width
                    spacing: 14

                    // =================================================================
                    // 0. AUDIO OUTPUTS & DUAL-SPEAKER MIXER (PIPEWIRE)
                    // =================================================================
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: audioCol.implicitHeight + 24
                        radius: 18
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        ColumnLayout {
                            id: audioCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: `󰕾  ÂM THANH & THIẾT BỊ PHÁT (${Store.audioSinks.length} ĐẦU RA)`
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Colors.primary
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    visible: Store.audioSinks.length >= 2
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: swTxt.implicitWidth + 22
                                    height: 28; radius: 14
                                    color: Colors.alpha(Colors.primary, 0.22)
                                    border.width: 1; border.color: Colors.primary
                                    Text {
                                        id: swTxt
                                        anchors.centerIn: parent
                                        text: "󰓡  Đổi nhanh loa"
                                        font.family: "Inter"; font.pixelSize: 11; font.bold: true
                                        color: Colors.primary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.cycleAudioSink()
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: mxTxt.implicitWidth + 20
                                    height: 28; radius: 14
                                    color: Colors.glassHighlight
                                    border.width: 1; border.color: Colors.glassBorderSubtle
                                    Text {
                                        id: mxTxt
                                        anchors.centerIn: parent
                                        text: "󰍜  Pavucontrol"
                                        font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium
                                        color: Colors.m3onSurface
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Store.settingsOpen = false
                                            Store.runCmd("pavucontrol")
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: Store.audioSinks
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isDefault: Store.defaultSink !== null && modelData.id === Store.defaultSink.id
                                    readonly property int sinkVol: modelData.ready && modelData.audio
                                        ? Math.max(0, Math.min(120, Math.round((modelData.audio.volume ?? 0) * 100)))
                                        : 0
                                    readonly property bool sinkMuted: Boolean(modelData.ready && modelData.audio && modelData.audio.muted)

                                    Layout.fillWidth: true
                                    height: 54
                                    radius: 14
                                    color: isDefault ? Colors.alpha(Colors.primary, 0.16) : Colors.glassHighlight
                                    border.width: isDefault ? 1.5 : 1
                                    border.color: isDefault ? Colors.primary : Colors.glassBorderSubtle

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        // Select Default Device Button Area
                                        Item {
                                            Layout.preferredWidth: 245
                                            Layout.fillHeight: true

                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 10

                                                Rectangle {
                                                    width: 32; height: 32; radius: 16
                                                    color: isDefault ? Colors.primary : Colors.glassCard
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: Store.sinkIcon(modelData)
                                                        font.family: "JetBrainsMono Nerd Font"
                                                        font.pixelSize: 15
                                                        color: isDefault ? Colors.m3onPrimary : Colors.m3onSurface
                                                    }
                                                }

                                                ColumnLayout {
                                                    spacing: 1
                                                    Layout.fillWidth: true
                                                    RowLayout {
                                                        spacing: 6
                                                        Layout.fillWidth: true
                                                        Text {
                                                            text: Store.sinkDisplayName(modelData)
                                                            font.family: "Inter"
                                                            font.pixelSize: 12
                                                            font.weight: Font.Bold
                                                            color: Colors.m3onSurface
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                    }
                                                    Text {
                                                        text: isDefault
                                                            ? `● Đang phát · ${Store.sinkSubtitle(modelData)}`
                                                            : `Nhấn để chọn · ${Store.sinkSubtitle(modelData)}`
                                                        font.family: "Inter"
                                                        font.pixelSize: 10
                                                        color: isDefault ? Colors.primary : Colors.m3onSurfaceVariant
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Store.setDefaultSink(modelData)
                                            }
                                        }

                                        // Mute Toggle for this specific device
                                        Rectangle {
                                            width: 28; height: 28; radius: 14
                                            color: sinkMuted ? Colors.alpha(Colors.error, 0.22) : Colors.glassCard
                                            border.width: 1
                                            border.color: sinkMuted ? Colors.error : Colors.glassBorderSubtle
                                            Text {
                                                anchors.centerIn: parent
                                                text: sinkMuted ? "󰝟" : (sinkVol > 50 ? "󰕾" : "󰖀")
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 13
                                                color: sinkMuted ? Colors.error : Colors.m3onSurface
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Store.toggleSinkMute(modelData)
                                            }
                                        }

                                        // Independent Volume Slider (0..120%)
                                        Item {
                                            Layout.fillWidth: true
                                            height: 26

                                            Rectangle {
                                                id: sinkTrack
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width
                                                height: 8
                                                radius: 4
                                                color: Colors.glassCard

                                                Rectangle {
                                                    readonly property real ratio: sinkMuted ? 0 : Math.max(0, Math.min(1, sinkVol / 120))
                                                    width: ratio <= 0 ? 0 : Math.max(8, parent.width * ratio)
                                                    height: parent.height
                                                    radius: 4
                                                    opacity: sinkMuted ? 0.35 : 1.0
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop { position: 0.0; color: sinkVol > 100 ? Colors.tertiary : Colors.primary }
                                                        GradientStop { position: 1.0; color: sinkVol > 100 ? Colors.error : Colors.tertiary }
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                property real wheelAccum: 0
                                                function applyX(mx) {
                                                    const r = Math.max(0, Math.min(1, mx / Math.max(1, width)))
                                                    Store.setSinkVolume(modelData, Math.round(r * 120))
                                                }
                                                onPressed: m => applyX(m.x)
                                                onPositionChanged: m => { if (pressed) applyX(m.x) }
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

                                        Text {
                                            text: sinkMuted ? "Mute" : `${sinkVol}%`
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: sinkMuted ? Colors.error : (isDefault ? Colors.primary : Colors.m3onSurfaceVariant)
                                            Layout.preferredWidth: 42
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }

            // =================================================================
            // 1. NVIDIA RTX 4050 DRIVER BANNER (EXPLAINS NOUVEAU & 1-CLICK FIX)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: gpuRow.implicitHeight + 24
                radius: 18
                color: Store.gpuDriver === "nouveau"
                    ? Colors.alpha(Colors.error, 0.16)
                    : Colors.alpha(Colors.primary, 0.14)
                border.width: 1
                border.color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.primary

                RowLayout {
                    id: gpuRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "󰢮"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 26
                        color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: Store.gpuDriver === "nouveau"
                                ? (Store.nvidiaPkgInstalled
                                    ? (Store.nvidiaModIndexed
                                        ? "Driver nvidia-open đã sẵn sàng — chỉ cần Reboot!"
                                        : "Đã cài nvidia-open nhưng UKI/depmod chưa nạp module!")
                                    : "Tại sao RTX 4050 đang hiện 'NOUVEAU'?")
                                : `NVIDIA GeForce RTX 4050 Mobile — Driver chính thức (${Store.gpuState})`
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Colors.m3onSurface
                        }
                        Text {
                            text: Store.gpuDriver === "nouveau"
                                ? (Store.nvidiaPkgInstalled
                                    ? "Gói nvidia-open đã có trên máy nhưng quá trình cài trước bị ngắt nên modules.dep & UKI (/etc/kernel/cmdline) chưa chứa nvidia. Bấm nút bên phải (~10 giây) để fix UKI & reboot!"
                                    : "Kernel Linux mặc định nạp driver mã nguồn mở 'nouveau'. Bấm nút bên phải để cài 'nvidia-open' + bật tiết kiệm pin RTD3 0W!")
                                : "Driver nvidia-open đã hoạt động chuẩn! Dùng lệnh 'nrun <app>' hoặc bật nút RTX 4050 trong App Launcher."
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: Colors.m3onSurfaceVariant
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: drvBtnTxt.implicitWidth + 28
                        height: 36
                        radius: 18
                        color: Store.gpuDriver === "nouveau" ? Colors.error : Colors.primary
                        Text {
                            id: drvBtnTxt
                            anchors.centerIn: parent
                            text: Store.gpuDriver === "nouveau"
                                ? (Store.nvidiaPkgInstalled ? "⚡ Fix UKI & Kích hoạt RTX" : "⚡ Cài Driver RTX 4050")
                                : "✓ Đã cài nvidia-open"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Store.gpuDriver === "nouveau" ? Colors.m3onError : Colors.m3onPrimary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Store.installNvidiaDriver()
                        }
                    }
                }
            }

            // =================================================================
            // 2. THEME RANDOMIZER, DARK/LIGHT MODE & MATUGEN SCHEMES
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: themeCol.implicitHeight + 24
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: themeCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰏘  CHỦ ĐỀ MÀU & WALLPAPER ĐỘNG (MATUGEN V4)"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.primary
                        }

                        Item { Layout.fillWidth: true }

                        // Random Wallpaper Button
                        Rectangle {
                            Layout.preferredHeight: 30; Layout.preferredWidth: rwTxt.implicitWidth + 24
                            height: 30; radius: 15
                            color: Colors.alpha(Colors.primary, 0.22)
                            border.width: 1; border.color: Colors.primary
                            Text { id: rwTxt; anchors.centerIn: parent; text: "󰒝  Random Ảnh Nền"; font.family: "Inter"; font.pixelSize: 11; font.bold: true; color: Colors.primary }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomWallpaper() }
                        }

                        // Random Wallpaper + Scheme Button
                        Rectangle {
                            Layout.preferredHeight: 30; Layout.preferredWidth: raTxt.implicitWidth + 24
                            height: 30; radius: 15
                            color: Colors.alpha(Colors.tertiary, 0.22)
                            border.width: 1; border.color: Colors.tertiary
                            Text { id: raTxt; anchors.centerIn: parent; text: "🎲  Random Ảnh + Chủ Đề"; font.family: "Inter"; font.pixelSize: 11; font.bold: true; color: Colors.tertiary }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomThemeAll() }
                        }

                        // Dark / Light Mode Toggle
                        Rectangle {
                            Layout.preferredHeight: 30; Layout.preferredWidth: dlTxt.implicitWidth + 24
                            height: 30; radius: 15
                            color: Store.currentMode === "light" ? Colors.primary : Colors.glassHighlight
                            border.width: 1; border.color: Colors.glassBorder
                            Text {
                                id: dlTxt
                                anchors.centerIn: parent
                                text: Store.currentMode === "dark" ? "󰖔  Chế độ: Dark" : "󰖨  Chế độ: Light"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.bold: true
                                color: Store.currentMode === "light" ? Colors.m3onPrimary : Colors.m3onSurface
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleDarkLight() }
                        }
                    }

                    // 7 Matugen Scheme Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: settingsWin.schemes
                            delegate: Rectangle {
                                readonly property bool sel: Store.currentScheme === modelData.id
                                Layout.fillWidth: true
                                height: 28
                                radius: 14
                                color: sel ? Colors.primary : Colors.glassHighlight
                                border.width: 1
                                border.color: sel ? Colors.primary : Colors.glassBorderSubtle

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: sel ? Font.Bold : Font.Medium
                                    color: sel ? Colors.m3onPrimary : Colors.m3onSurface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.applyScheme(modelData.id)
                                }
                            }
                        }
                    }

                    // Automatic Wallpaper Slideshow Timer Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: "󰔟  Tự động đổi ảnh nền:"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: Colors.m3onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Repeater {
                            model: [
                                { mins: 0,  label: "Tắt" },
                                { mins: 5,  label: "5 phút" },
                                { mins: 15, label: "15 phút" },
                                { mins: 30, label: "30 phút" },
                                { mins: 60, label: "60 phút" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Store.slideshowMins === modelData.mins
                                height: 26
                                width: slTxt.implicitWidth + 18
                                radius: 13
                                color: sel ? Colors.tertiary : Colors.glassHighlight
                                border.width: 1
                                border.color: sel ? Colors.tertiary : Colors.glassBorderSubtle
                                Text {
                                    id: slTxt
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: sel ? Font.Bold : Font.Medium
                                    color: sel ? Colors.m3onTertiary : Colors.m3onSurface
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.setTuning("slideshow_mins", modelData.mins)
                                }
                            }
                        }
                    }
                }
            }
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: animCol.implicitHeight + 24
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: animCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰘷  HIỆU ỨNG CHUYỂN ĐỘNG (ANIMATION) & HIỆU NĂNG 144Hz"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.primary
                        }
                        Item { Layout.fillWidth: true }

                        // Power Profile Switcher
                        Repeater {
                            model: [
                                { id: "power-saver", label: "󰌪 Tiết kiệm pin" },
                                { id: "balanced",    label: "󰾅 Cân bằng" },
                                { id: "performance", label: "󰓅 Hiệu năng cao" }
                            ]
                            delegate: Rectangle {
                                readonly property bool act: Store.profile === modelData.id
                                height: 26
                                width: ppTxt.implicitWidth + 16
                                radius: 13
                                color: act ? Colors.tertiary : Colors.glassHighlight
                                Text {
                                    id: ppTxt
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.bold: act
                                    color: act ? Colors.m3onTertiary : Colors.m3onSurfaceVariant
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.setProfile(modelData.id)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: settingsWin.animPresets
                            delegate: Rectangle {
                                readonly property bool sel: Store.animPreset === modelData.id
                                Layout.fillWidth: true
                                height: 52
                                radius: 14
                                color: sel ? Colors.alpha(Colors.primary, 0.24) : Colors.glassHighlight
                                border.width: sel ? 1.5 : 1
                                border.color: sel ? Colors.primary : Colors.glassBorderSubtle

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        font.family: "Inter"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: sel ? Colors.primary : Colors.m3onSurface
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.desc
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                        color: Colors.m3onSurfaceVariant
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.setTuning("anim_preset", modelData.id)
                                }
                            }
                        }
                    }
                }
            }

                    // =================================================================
                    // 3.5. DOCK SUITE QUICK SELECTOR (6 PRESETS + LIVE STUDIO)
                    // =================================================================
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: dockCardCol.implicitHeight + 24
                        radius: 18
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        ColumnLayout {
                            id: dockCardCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: "󱂬  THANH DOCK ĐA PHONG CÁCH (8 PRESETS)"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Colors.primary
                                }
                                Item { Layout.fillWidth: true }

                                // Quick On/Off
                                Rectangle {
                                    height: 26; width: dkEnTxt.implicitWidth + 18; radius: 13
                                    color: Store.dockEnabled ? Colors.primary : Colors.glassHighlight
                                    Text {
                                        id: dkEnTxt; anchors.centerIn: parent
                                        text: Store.dockEnabled ? "Dock: BẬT" : "Dock: TẮT"
                                        font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                        color: Store.dockEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.setTuning("dock_enabled", !Store.dockEnabled)
                                    }
                                }

                                // Open Live Dock Studio
                                Rectangle {
                                    height: 26; width: dkStTxt.implicitWidth + 20; radius: 13
                                    color: Colors.alpha(Colors.tertiary, 0.24)
                                    border.width: 1; border.color: Colors.tertiary
                                    Text {
                                        id: dkStTxt; anchors.centerIn: parent
                                        text: "󱂬  Mở Dock Studio"
                                        font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                        color: Colors.tertiary
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Store.toggleDockStudio()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Repeater {
                                    model: Store.dockPresets
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool sel: Store.dockStyle === modelData.id
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 15
                                        color: sel ? Colors.primary : Colors.glassHighlight
                                        border.width: 1
                                        border.color: sel ? Colors.primary : Colors.glassBorderSubtle
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name.split(" ")[0]
                                            font.family: "Inter"; font.pixelSize: 10
                                            font.weight: sel ? Font.Bold : Font.Medium
                                            color: sel ? Colors.m3onPrimary : Colors.m3onSurface
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: Store.applyDockPreset(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

            // =================================================================
            // 4. FROSTED GLASS BLUR, TERMINAL OPACITY & GEOMETRY SLIDERS
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: blurCol.implicitHeight + 28
                radius: 18
                color: Colors.glassCard
                border.width: 1
                border.color: Colors.glassBorderSubtle

                ColumnLayout {
                    id: blurCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰂵  KÍNH MỜ (BLUR), ĐỘ TRONG SUỐT TERMINAL & BO GÓC"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.primary
                        }
                        Item { Layout.fillWidth: true }

                        // Toggle Blur On/Off
                        Rectangle {
                            height: 26; width: blTxt.implicitWidth + 18; radius: 13
                            color: Store.blurEnabled ? Colors.primary : Colors.glassHighlight
                            Text {
                                id: blTxt; anchors.centerIn: parent
                                text: Store.blurEnabled ? "Blur: ĐANG BẬT" : "Blur: ĐANG TẮT"
                                font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                color: Store.blurEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setTuning("blur_enabled", !Store.blurEnabled)
                            }
                        }

                        // Toggle VRR 144Hz
                        Rectangle {
                            height: 26; width: vrrTxt.implicitWidth + 18; radius: 13
                            color: Store.vrrEnabled ? Colors.primary : Colors.glassHighlight
                            Text {
                                id: vrrTxt; anchors.centerIn: parent
                                text: Store.vrrEnabled ? "144Hz VRR: BẬT" : "144Hz VRR: TẮT"
                                font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                color: Store.vrrEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setTuning("vrr_enabled", !Store.vrrEnabled)
                            }
                        }
                    }

                    // Hyprland 0.57 effects — glow / wobble / motion blur
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            height: 26; width: glowTxt.implicitWidth + 18; radius: 13
                            color: Store.glowEnabled ? Colors.primary : Colors.glassHighlight
                            Text {
                                id: glowTxt; anchors.centerIn: parent
                                text: Store.glowEnabled ? "Glow: BẬT" : "Glow: TẮT"
                                font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                color: Store.glowEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setTuning("glow_enabled", !Store.glowEnabled)
                            }
                        }

                        Rectangle {
                            height: 26; width: wobbleTxt.implicitWidth + 18; radius: 13
                            color: Store.wobbleEnabled ? Colors.primary : Colors.glassHighlight
                            Text {
                                id: wobbleTxt; anchors.centerIn: parent
                                text: Store.wobbleEnabled ? "Wobble: BẬT" : "Wobble: TẮT"
                                font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                color: Store.wobbleEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setTuning("wobble_enabled", !Store.wobbleEnabled)
                            }
                        }

                        Rectangle {
                            height: 26; width: mbTxt.implicitWidth + 18; radius: 13
                            color: Store.motionBlurEnabled ? Colors.primary : Colors.glassHighlight
                            Text {
                                id: mbTxt; anchors.centerIn: parent
                                text: Store.motionBlurEnabled ? "Motion Blur: BẬT" : "Motion Blur: TẮT"
                                font.family: "Inter"; font.pixelSize: 10; font.bold: true
                                color: Store.motionBlurEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setTuning("motion_blur_enabled", !Store.motionBlurEnabled)
                            }
                        }
                    }

                    SettingSlider {
                        label: "Độ mờ kính (Blur Size)"
                        value: Store.blurSize
                        minValue: 2; maxValue: 18; suffix: "px"
                        onChanged: v => Store.setTuning("blur_size", v)
                    }

                    SettingSlider {
                        label: "Số lớp Blur (Passes)"
                        value: Store.blurPasses
                        minValue: 1; maxValue: 5; suffix: "x"
                        onChanged: v => Store.setTuning("blur_passes", v)
                    }

                    SettingSlider {
                        label: "Độ đục Terminal (Kitty)"
                        value: Store.termOpacity
                        minValue: 45; maxValue: 100; suffix: "%"
                        onChanged: v => Store.setTuning("term_opacity", v)
                    }

                    SettingSlider {
                        label: "Bo góc cửa sổ (Rounding)"
                        value: Store.rounding
                        minValue: 0; maxValue: 28; suffix: "px"
                        onChanged: v => Store.setTuning("rounding", v)
                    }

                    SettingSlider {
                        label: "Khoảng cách viền (Gaps)"
                        value: Store.gapsOut
                        minValue: 0; maxValue: 28; suffix: "px"
                        onChanged: v => Store.setTuning("gaps_out", v)
                    }
                }
            }
                }
            }
        }
    }
}

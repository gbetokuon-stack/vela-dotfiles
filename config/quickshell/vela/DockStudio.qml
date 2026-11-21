import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: studioWin

    property real openAnim: Store.dockStudioOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.dockStudioOpen ? 240 : 150
            easing.type: Store.dockStudioOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.dockStudioOpen || openAnim > 0.005

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-dock-studio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.dockStudioOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click outside card to close — NO dim_around so user sees the live Dock morphing at 144Hz!
    MouseArea {
        anchors.fill: parent
        onClicked: Store.dockStudioOpen = false
    }

    component DockSlider: RowLayout {
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
            font.pixelSize: 11
            color: Colors.m3onSurface
            Layout.preferredWidth: 148
        }

        Item {
            Layout.fillWidth: true
            height: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 7
                radius: 3.5
                color: Colors.glassHighlight

                Rectangle {
                    readonly property real ratio: Math.max(0, Math.min(1, (value - minValue) / Math.max(1, maxValue - minValue)))
                    width: Math.max(7, parent.width * ratio)
                    height: parent.height
                    radius: 3.5
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
                    const r = Math.max(0, Math.min(1, mx / Math.max(1, width)))
                    changed(Math.round(minValue + r * (maxValue - minValue)))
                }
                onPressed: m => applyX(m.x)
                onPositionChanged: m => { if (pressed) applyX(m.x) }
            }
        }

        Text {
            text: `${value}${suffix}`
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.bold: true
            color: Colors.primary
            Layout.preferredWidth: 42
            horizontalAlignment: Text.AlignRight
        }
    }

    component ToggleChip: Rectangle {
        property string label: ""
        property bool checked: false
        signal toggled()

        Layout.fillWidth: true
        height: 30
        radius: 15
        color: checked ? Colors.alpha(Colors.primary, 0.22) : Colors.glassHighlight
        border.width: checked ? 1.5 : 1
        border.color: checked ? Colors.primary : Colors.glassBorderSubtle
        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: checked ? "●" : "○"
                font.pixelSize: 9
                color: checked ? Colors.primary : Colors.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: label
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: checked ? Font.Bold : Font.Medium
                color: checked ? Colors.m3onSurface : Colors.m3onSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }

    // Main floating studio card positioned nicely above bottom dock so dock stays 100% visible!
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 64
        width: 820
        height: Math.min(parent.height - 170, 720)
        radius: 26
        color: Colors.alpha(Colors.surfaceContainerLowest, 0.88)
        border.width: 1
        border.color: Colors.glassBorder
        opacity: studioWin.openAnim
        scale: 0.94 + 0.06 * studioWin.openAnim
        transform: Translate { y: (1.0 - studioWin.openAnim) * 14 }

        focus: Store.dockStudioOpen
        Keys.onEscapePressed: Store.dockStudioOpen = false
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            // =================================================================
            // HEADER
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 38; height: 38; radius: 19
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󱂬"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Vela Dock Studio · 8 Kiểu Thiết Kế & Tùy Biến Trực Tiếp"
                        font.family: "Inter"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: "Chọn preset bên dưới và xem Dock biến hình ngay lập tức ở 144Hz (Super+Shift+B · Super+Alt+B)"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                // Master Dock On/Off Pill
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: enTxt.implicitWidth + 24
                    radius: 15
                    color: Store.dockEnabled ? Colors.primary : Colors.glassCard
                    border.width: 1
                    border.color: Store.dockEnabled ? Colors.primary : Colors.glassBorderSubtle
                    Text {
                        id: enTxt
                        anchors.centerIn: parent
                        text: Store.dockEnabled ? "● Dock: BẬT" : "○ Dock: TẮT"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.bold: true
                        color: Store.dockEnabled ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.setTuning("dock_enabled", !Store.dockEnabled)
                    }
                }

                // Reset Dock
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: rstTxt.implicitWidth + 20
                    radius: 15
                    color: Colors.glassCard
                    border.width: 1
                    border.color: Colors.glassBorderSubtle
                    Text { id: rstTxt; anchors.centerIn: parent; text: "↺ Mặc định"; font.family: "Inter"; font.pixelSize: 10; color: Colors.m3onSurfaceVariant }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.resetDock() }
                }

                // Close
                Rectangle {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 30
                    radius: 15; color: Colors.glassCard
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: Colors.m3onSurface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.dockStudioOpen = false }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: bodyCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    id: bodyCol
                    width: parent.width
                    spacing: 12

                    // =========================================================
                    // 1. 6 VISUAL DOCK PRESET CARDS (2x3 GRID WITH MINI MOCKUPS!)
                    // =========================================================
                    Text {
                        text: "󰏘  CHỌN PHONG CÁCH DOCK (8 PRESETS)"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        color: Colors.primary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: Store.dockPresets
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: Store.dockStyle === modelData.id

                                Layout.fillWidth: true
                                implicitHeight: 112
                                radius: 16
                                color: sel ? Colors.alpha(Colors.primary, 0.18) : Colors.glassCard
                                border.width: sel ? 1.8 : 1
                                border.color: sel ? Colors.primary : Colors.glassBorderSubtle
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    // Mini Visual Silhouette Preview Canvas
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        radius: 10
                                        color: Colors.alpha(Colors.surfaceContainerLowest, 0.72)
                                        border.width: 1
                                        border.color: Colors.glassBorderSubtle
                                        clip: true

                                        // Preview 1: Nocturne Prism
                                        Rectangle {
                                            visible: modelData.id === "prism"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 6
                                            width: 126; height: 22; radius: 11
                                            color: Colors.surfaceContainerHigh
                                            border.width: 1; border.color: Colors.alpha(Colors.primary, 0.55)
                                            Rectangle {
                                                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                                width: 80; height: 1.5; color: Colors.primary
                                            }
                                            Row {
                                                anchors.centerIn: parent; spacing: 6
                                                Repeater {
                                                    model: 5
                                                    delegate: Column {
                                                        spacing: 2
                                                        Rectangle { width: 12; height: 12; radius: 4; color: index === 1 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.35) }
                                                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: index === 1 ? 8 : 3; height: 2; radius: 1; color: index === 1 ? Colors.primary : "transparent" }
                                                    }
                                                }
                                            }
                                        }

                                        // Preview 2: macOS Liquid (Wave Zoom!)
                                        Rectangle {
                                            visible: modelData.id === "macos"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 5
                                            width: 132; height: 22; radius: 11
                                            color: Colors.alpha(Colors.surfaceContainerHigh, 0.75)
                                            border.width: 1; border.color: Colors.alpha(Colors.m3onSurface, 0.35)
                                            Row {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 4
                                                spacing: 5
                                                Repeater {
                                                    model: [11, 14, 19, 14, 11]
                                                    delegate: Rectangle {
                                                        anchors.bottom: parent.bottom
                                                        width: modelData; height: modelData; radius: Math.round(modelData * 0.3)
                                                        color: index === 2 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.45)
                                                    }
                                                }
                                            }
                                        }

                                        // Preview 3: Dynamic Islands (3 Split Pods)
                                        Row {
                                            visible: modelData.id === "island"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 7
                                            spacing: 6
                                            Rectangle {
                                                width: 24; height: 20; radius: 10
                                                color: Colors.surfaceContainerHigh; border.width: 1; border.color: Colors.glassBorder
                                                Rectangle { anchors.centerIn: parent; width: 9; height: 9; radius: 4.5; color: Colors.primary }
                                            }
                                            Rectangle {
                                                width: 78; height: 20; radius: 10
                                                color: Colors.surfaceContainerHigh; border.width: 1; border.color: Colors.alpha(Colors.primary, 0.5)
                                                Row {
                                                    anchors.centerIn: parent; spacing: 5
                                                    Repeater { model: 4; Rectangle { width: 11; height: 11; radius: 3.5; color: index === 0 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.4) } }
                                                }
                                            }
                                            Rectangle {
                                                width: 30; height: 20; radius: 10
                                                color: Colors.surfaceContainerHigh; border.width: 1; border.color: Colors.glassBorder
                                                Rectangle { anchors.centerIn: parent; width: 12; height: 7; radius: 3.5; color: Colors.tertiary }
                                            }
                                        }

                                        // Preview 4: Cyber Neon HUD
                                        Rectangle {
                                            visible: modelData.id === "cyber"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 6
                                            width: 132; height: 22; radius: 4
                                            color: Colors.surfaceContainerLowest
                                            border.width: 1.5; border.color: Colors.primary
                                            Rectangle {
                                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                                anchors.leftMargin: 8; anchors.rightMargin: 8; height: 2
                                                color: Colors.tertiary
                                            }
                                            Row {
                                                anchors.centerIn: parent; spacing: 6
                                                Repeater {
                                                    model: 5
                                                    delegate: Rectangle {
                                                        width: 13; height: 13; radius: 3
                                                        color: index === 2 ? Colors.alpha(Colors.primary, 0.45) : Colors.surfaceContainerHigh
                                                        border.width: index === 2 ? 1 : 0; border.color: Colors.primary
                                                    }
                                                }
                                            }
                                        }

                                        // Preview 5: Full-Width Glass Taskbar
                                        Rectangle {
                                            visible: modelData.id === "taskbar"
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                            height: 20; radius: 0
                                            color: Colors.surfaceContainerHigh
                                            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Colors.primary }
                                            Rectangle { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: Colors.primary }
                                            Row {
                                                anchors.centerIn: parent; spacing: 6
                                                Repeater { model: 4; Rectangle { width: 11; height: 11; radius: 3; color: index === 1 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.45) } }
                                            }
                                            Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 8; radius: 4; color: Colors.alpha(Colors.m3onSurface, 0.25) }
                                        }

                                        // Preview 6: Ultra Minimal
                                        Rectangle {
                                            visible: modelData.id === "minimal"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 8
                                            width: 92; height: 16; radius: 8
                                            color: Colors.alpha(Colors.surfaceContainerHigh, 0.55)
                                            border.width: 1; border.color: Colors.glassBorderSubtle
                                            Row {
                                                anchors.centerIn: parent; spacing: 6
                                                Repeater { model: 4; Rectangle { width: 9; height: 9; radius: 3; color: index === 0 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.35) } }
                                            }
                                        }

                                        // Preview 7: Material Aura (Glow Pill)
                                        Rectangle {
                                            visible: modelData.id === "aura"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 6
                                            width: 118; height: 24; radius: 12
                                            color: Colors.alpha(Colors.surfaceContainer, 0.9)
                                            border.width: 1.5; border.color: Colors.alpha(Colors.primary, 0.6)
                                            Row {
                                                anchors.centerIn: parent; spacing: 6
                                                Repeater {
                                                    model: 4
                                                    delegate: Rectangle {
                                                        width: 14; height: 14; radius: 7
                                                        color: index === 1 ? Colors.alpha(Colors.primary, 0.45) : "transparent"
                                                        Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: index === 1 ? Colors.primary : Colors.alpha(Colors.m3onSurface, 0.42) }
                                                    }
                                                }
                                            }
                                        }

                                        // Preview 8: Arch Tiling Strip
                                        Rectangle {
                                            visible: modelData.id === "archbar"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 7
                                            width: 128; height: 20; radius: 6
                                            color: Colors.surfaceContainerLowest
                                            border.width: 1; border.color: Colors.glassBorder
                                            Row {
                                                anchors.centerIn: parent; spacing: 4
                                                Rectangle { width: 12; height: 10; radius: 3; color: Colors.primary }
                                                Rectangle { width: 8; height: 10; radius: 3; color: Colors.glassHighlight }
                                                Rectangle { width: 1; height: 10; color: Colors.glassBorderSubtle }
                                                Repeater {
                                                    model: 4
                                                    delegate: Rectangle {
                                                        width: 11; height: 11; radius: 3
                                                        color: Colors.surfaceContainerHigh
                                                        border.width: index === 0 ? 1.2 : 0; border.color: Colors.primary
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Preset Name + Badge
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Text {
                                            text: modelData.name
                                            font.family: "Inter"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: sel ? Colors.primary : Colors.m3onSurface
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Rectangle {
                                            height: 16; width: bdg.implicitWidth + 10; radius: 8
                                            color: sel ? Colors.primary : Colors.glassHighlight
                                            Text {
                                                id: bdg; anchors.centerIn: parent
                                                text: modelData.badge
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: sel ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                        color: Colors.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Store.applyDockPreset(modelData.id)
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 2. POSITION, VISIBILITY MODE & INDICATOR STYLE
                    // =========================================================
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: posCol.implicitHeight + 22
                        radius: 18
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        ColumnLayout {
                            id: posCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            // Position + Visibility Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                // Position
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "󰀻  VỊ TRÍ DOCK"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Colors.primary }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "bottom", label: "󰘮 Dưới" },
                                                { id: "left",   label: "󰘬 Trái" },
                                                { id: "right",  label: "󰘭 Phải" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool act: Store.dockPosition === modelData.id
                                                Layout.fillWidth: true; height: 28; radius: 14
                                                color: act ? Colors.primary : Colors.glassHighlight
                                                border.width: 1; border.color: act ? Colors.primary : Colors.glassBorderSubtle
                                                Text {
                                                    anchors.centerIn: parent; text: modelData.label
                                                    font.family: "Inter"; font.pixelSize: 11; font.bold: act
                                                    color: act ? Colors.m3onPrimary : Colors.m3onSurface
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.setTuning("dock_position", modelData.id) }
                                            }
                                        }
                                    }
                                }

                                // Visibility Mode
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "󰈈  CHẾ ĐỘ HIỂN THỊ"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Colors.primary }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "always",   label: "Luôn hiện" },
                                                { id: "smart",    label: "Thông minh" },
                                                { id: "autohide", label: "Tự ẩn" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool act: Store.dockVisibility === modelData.id
                                                Layout.fillWidth: true; height: 28; radius: 14
                                                color: act ? Colors.tertiary : Colors.glassHighlight
                                                border.width: 1; border.color: act ? Colors.tertiary : Colors.glassBorderSubtle
                                                Text {
                                                    anchors.centerIn: parent; text: modelData.label
                                                    font.family: "Inter"; font.pixelSize: 11; font.bold: act
                                                    color: act ? Colors.m3onTertiary : Colors.m3onSurface
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.setTuning("dock_visibility", modelData.id) }
                                            }
                                        }
                                    }
                                }
                            }

                            // Running Indicator Style Row
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text { text: "󰐃  KIỂU CHỈ BÁO APP ĐANG CHẠY"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.bold: true; color: Colors.primary }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: [
                                            { id: "pill", label: "━  Pill" },
                                            { id: "dot",  label: "●  Dot" },
                                            { id: "bar",  label: "▬  Laser Bar" },
                                            { id: "glow", label: "✦  Aura Glow" },
                                            { id: "ring", label: "▢  Border Ring" }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            readonly property bool act: Store.dockIndicator === modelData.id
                                            Layout.fillWidth: true; height: 28; radius: 14
                                            color: act ? Colors.alpha(Colors.primary, 0.25) : Colors.glassHighlight
                                            border.width: act ? 1.5 : 1; border.color: act ? Colors.primary : Colors.glassBorderSubtle
                                            Text {
                                                anchors.centerIn: parent; text: modelData.label
                                                font.family: "Inter"; font.pixelSize: 10; font.bold: act
                                                color: act ? Colors.primary : Colors.m3onSurface
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.setTuning("dock_indicator", modelData.id) }
                                        }
                                    }
                                }
                            }

                            // Feature Toggles Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                ToggleChip {
                                    label: "Phóng to lượn sóng"
                                    checked: Store.dockMagnify
                                    onToggled: Store.setTuning("dock_magnify", !Store.dockMagnify)
                                }
                                ToggleChip {
                                    label: "Nhãn Tooltip"
                                    checked: Store.dockShowLabels
                                    onToggled: Store.setTuning("dock_show_labels", !Store.dockShowLabels)
                                }
                                ToggleChip {
                                    label: "App đang chạy"
                                    checked: Store.dockShowRunning
                                    onToggled: Store.setTuning("dock_show_running", !Store.dockShowRunning)
                                }
                                ToggleChip {
                                    label: "Nút tiện ích"
                                    checked: Store.dockShowUtils
                                    onToggled: Store.setTuning("dock_show_utils", !Store.dockShowUtils)
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 3. PRECISION LIVE SLIDERS
                    // =========================================================
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: slCol.implicitHeight + 22
                        radius: 18
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        ColumnLayout {
                            id: slCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            Text {
                                text: "󰺾  TINH CHỈNH KÍCH THƯỚC, ĐỘ MỜ & HIỆU ỨNG"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.bold: true
                                color: Colors.primary
                            }

                            DockSlider {
                                label: "Kích thước Icon"
                                value: Store.dockIconSize
                                minValue: 32; maxValue: 60; suffix: "px"
                                onChanged: v => Store.setTuning("dock_icon_size", v)
                            }

                            DockSlider {
                                label: "Độ phóng to (Hover)"
                                value: Store.dockMagScale
                                minValue: 110; maxValue: 165; suffix: "%"
                                onChanged: v => Store.setTuning("dock_mag_scale", v)
                            }

                            DockSlider {
                                label: "Độ đục kính (Opacity)"
                                value: Store.dockOpacity
                                minValue: 30; maxValue: 98; suffix: "%"
                                onChanged: v => Store.setTuning("dock_opacity", v)
                            }

                            DockSlider {
                                label: "Bo góc khung (Radius)"
                                value: Store.dockRadius
                                minValue: 0; maxValue: 32; suffix: "px"
                                onChanged: v => Store.setTuning("dock_radius", v)
                            }

                            DockSlider {
                                label: "Khoảng cách viền"
                                value: Store.dockMargin
                                minValue: 0; maxValue: 24; suffix: "px"
                                onChanged: v => Store.setTuning("dock_margin", v)
                            }
                        }
                    }

                    // =========================================================
                    // 4. PINNED APPS QUICK MANAGER
                    // =========================================================
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: pinCol.implicitHeight + 22
                        radius: 18
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        ColumnLayout {
                            id: pinCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "󰐃  ỨNG DỤNG GHIM TRÊN DOCK (NHẤN ĐỂ BẬT/TẮT · HOẶC CHUỘT PHẢI LÊN ICON)"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Colors.primary
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { id: "kitty",           label: "󰆍  Kitty" },
                                        { id: "firefox",         label: "󰈹  Firefox" },
                                        { id: "org.kde.dolphin", label: "󰉋  Dolphin" },
                                        { id: "btop",            label: "󰍛  Btop" },
                                        { id: "pavucontrol",     label: "󰕾  Audio Mixer" },
                                        { id: "blueman-manager", label: "󰂯  Bluetooth" },
                                        { id: "nwg-look",        label: "󰏘  GTK Theme" },
                                        { id: "qt6ct",           label: "󰏘  Qt6 Theme" },
                                        { id: "vela-settings-studio", label: "󰒓  Rice Studio" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool pinned: Store.isDockAppPinned(modelData.id)
                                        height: 26
                                        width: pTxt.implicitWidth + 20
                                        radius: 13
                                        color: pinned ? Colors.alpha(Colors.primary, 0.24) : Colors.glassHighlight
                                        border.width: 1
                                        border.color: pinned ? Colors.primary : Colors.glassBorderSubtle

                                        Text {
                                            id: pTxt
                                            anchors.centerIn: parent
                                            text: (pinned ? "✓ " : "+ ") + modelData.label
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.weight: pinned ? Font.Bold : Font.Medium
                                            color: pinned ? Colors.primary : Colors.m3onSurfaceVariant
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Store.togglePinDockApp(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

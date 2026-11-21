import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: layoutWin
    property real openAnim: Store.layoutOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.layoutOpen ? 240 : 150
            easing.type: Store.layoutOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.layoutOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-layout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.layoutOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property var layoutModes: [
        { id: "dwindle",   icon: "󰕮", title: "Dwindle",   desc: "Chia nhánh linh hoạt" },
        { id: "scrolling", icon: "󰝘", title: "Scrolling", desc: "Cột ngang kiểu Niri" },
        { id: "master",    icon: "󰕰", title: "Master",    desc: "Ngăn chính + Cột phụ" }
    ]

    readonly property var ratioPresets: [
        { left: 50, right: 50, label: "50 / 50", hint: "Đều nhau",    key: "Alt+1" },
        { left: 20, right: 80, label: "20 / 80", hint: "Nhỏ · Lớn",   key: "Alt+2" },
        { left: 30, right: 70, label: "30 / 70", hint: "Side · Main", key: "Alt+3" },
        { left: 70, right: 30, label: "70 / 30", hint: "Main · Side", key: "Alt+4" },
        { left: 80, right: 20, label: "80 / 20", hint: "Lớn · Nhỏ",   key: "Alt+5" }
    ]

    // Click anywhere outside to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: Store.layoutOpen = false
    }

    Rectangle {
        x: 14
        y: 60
        width: 420
        height: cardCol.implicitHeight + 32
        radius: 24
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: layoutWin.openAnim
        scale: 0.94 + 0.06 * layoutWin.openAnim
        transformOrigin: Item.TopLeft
        transform: Translate { y: (1.0 - layoutWin.openAnim) * -10 }

        focus: Store.layoutOpen
        Keys.onEscapePressed: Store.layoutOpen = false
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 34; height: 34; radius: 17
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰕮"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: "Chia Ngăn Task Linh Hoạt"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: "Chọn tỷ lệ 50/50 · 20/80 hoặc ghép 2 task cạnh nhau"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: Colors.glassCard
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 12; color: Colors.m3onSurface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.layoutOpen = false }
                }
            }

            // Section 1: 3 Tiling Layout Modes
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "CHẾ ĐỘ CHIA NGĂN (LAYOUT)"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.bold: true
                        color: Colors.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Super + Z"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Colors.m3onSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: layoutWin.layoutModes
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool sel: Store.layoutMode === modelData.id

                            Layout.fillWidth: true
                            height: 62
                            radius: 14
                            color: sel ? Colors.alpha(Colors.primary, 0.24) : Colors.glassCard
                            border.width: sel ? 1.5 : 1
                            border.color: sel ? Colors.primary : Colors.glassBorderSubtle

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                    color: sel ? Colors.primary : Colors.m3onSurface
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.title
                                    font.family: "Inter"
                                    font.pixelSize: 11
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
                                onClicked: Store.setLayoutMode(modelData.id)
                            }
                        }
                    }
                }
            }

            // Section 2: Split Ratio Presets (50/50, 20/80, 30/70, 70/30, 80/20)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "TỶ LỆ 2 NGĂN CẠNH NHAU"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.bold: true
                        color: Colors.primary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Super + Alt + 1..5 / 0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Colors.m3onSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: layoutWin.ratioPresets
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool sel: Store.layoutRatio === modelData.left

                            Layout.fillWidth: true
                            height: 70
                            radius: 14
                            color: sel ? Colors.alpha(Colors.primary, 0.22) : Colors.glassCard
                            border.width: sel ? 1.5 : 1
                            border.color: sel ? Colors.primary : Colors.glassBorderSubtle

                            Behavior on color { ColorAnimation { duration: 140 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 5

                                // Visual 2-pane split ratio preview bar
                                RowLayout {
                                    Layout.fillWidth: true
                                    height: 18
                                    spacing: 3

                                    Rectangle {
                                        Layout.preferredWidth: Math.max(8, (parent.width - 3) * (modelData.left / 100.0))
                                        Layout.fillHeight: true
                                        radius: 4
                                        color: sel ? Colors.primary : Colors.alpha(Colors.primary, 0.55)
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 4
                                        color: sel ? Colors.tertiary : Colors.alpha(Colors.m3onSurfaceVariant, 0.28)
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: sel ? Colors.primary : Colors.m3onSurface
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.hint
                                    font.family: "Inter"
                                    font.pixelSize: 8
                                    color: Colors.m3onSurfaceVariant
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Store.setSplitRatio(modelData.left)
                            }
                        }
                    }
                }
            }

            // Section 3: Quick Side-by-Side & Pane Controls (2x2 Grid)
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        { icon: "󰯌", label: "2 Task cạnh nhau",  sub: "Ngang 50/50 · Alt+H",  act: "side_by_side" },
                        { icon: "󰤼", label: "Đổi Ngang ↔ Dọc",   sub: "Super + J",            act: "toggle_orientation" },
                        { icon: "󰓡", label: "Đảo vị trí 2 bên",  sub: "Super + Shift + J",    act: "swap_panes" },
                        { icon: "󰁌", label: "Ra ngăn chính",     sub: "Tách cột · Alt+Enter", act: "promote_pane" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 48
                        radius: 13
                        color: actHover.containsMouse ? Colors.glassHighlight : Colors.glassCard
                        border.width: 1
                        border.color: actHover.containsMouse ? Colors.primary : Colors.glassBorderSubtle

                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: Colors.primary
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.label
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Colors.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.sub
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: Colors.m3onSurfaceVariant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: actHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.act === "side_by_side") {
                                    Store.tilingSideBySide(50)
                                } else {
                                    Store.tilingAction(modelData.act)
                                }
                            }
                        }
                    }
                }
            }

            // Footer Keyboard Tips
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 10
                color: Colors.glassHighlight

                Text {
                    anchors.centerIn: parent
                    text: "Kéo giãn: Super+Ctrl+←→↑↓  ·  Tinh chỉnh: Super - / =  ·  Gắn cạnh: Super+Alt+←→"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Colors.m3onSurfaceVariant
                }
            }
        }
    }
}

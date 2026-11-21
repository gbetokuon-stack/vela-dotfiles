import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: kbWin
    property real openAnim: Store.cheatsheetOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.cheatsheetOpen ? 240 : 150
            easing.type: Store.cheatsheetOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.cheatsheetOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-cheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property string selectedCat: "All"

    Connections {
        target: Store
        function onCheatsheetOpenChanged() {
            if (Store.cheatsheetOpen) {
                kbWin.query = ""
                kbWin.selectedCat = "All"
                kbSearch.text = ""
                kbSearch.forceActiveFocus()
            }
        }
    }

    readonly property var categories: {
        const list = Store.keybinds || []
        const seen = { "All": true }
        const out = ["All"]
        for (let i = 0; i < list.length; i++) {
            const c = list[i].category || "General"
            if (!seen[c]) {
                seen[c] = true
                out.push(c)
            }
        }
        return out
    }

    readonly property var filteredBinds: {
        const q = query.trim().toLowerCase()
        const list = Store.keybinds || []
        const out = []
        for (let i = 0; i < list.length; i++) {
            const b = list[i]
            if (selectedCat !== "All" && b.category !== selectedCat) continue
            if (q.length > 0) {
                const hay = `${b.keys} ${b.desc} ${b.category}`.toLowerCase()
                if (!hay.includes(q)) continue
            }
            out.push(b)
        }
        return out
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Store.cheatsheetOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 820
        height: 600
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: kbWin.openAnim
        scale: 0.93 + 0.07 * kbWin.openAnim
        transform: Translate { y: (1.0 - kbWin.openAnim) * 14 }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 38; height: 38; radius: 19
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Vela Hyprland Keybinds"
                        font.family: "Inter"
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: `Live-parsed from ~/.config/hypr/keybinds.lua  ·  ${kbWin.filteredBinds.length} shortcuts  ·  Super + /`
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Colors.glassCard
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 13; color: Colors.m3onSurface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.cheatsheetOpen = false }
                }
            }

            // Search input
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 21
                color: Colors.glassCard
                border.width: kbSearch.activeFocus ? 1.5 : 1
                border.color: kbSearch.activeFocus ? Colors.primary : Colors.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10
                    Text { text: "󰍉"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: Colors.primary }
                    TextInput {
                        id: kbSearch
                        Layout.fillWidth: true
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: Colors.m3onSurface
                        focus: true
                        onTextChanged: kbWin.query = text
                        Keys.onEscapePressed: Store.cheatsheetOpen = false
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: parent.text.length === 0
                            text: "Tìm phím tắt (vd: wallpaper, clipboard, screenshot, float, workspace)..."
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: Colors.m3onSurfaceVariant
                        }
                    }
                }
            }

            // Category chips
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                contentWidth: catRow.implicitWidth
                clip: true
                Row {
                    id: catRow
                    spacing: 6
                    Repeater {
                        model: kbWin.categories
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool active: kbWin.selectedCat === modelData
                            height: 28
                            width: cTxt.implicitWidth + 20
                            radius: 14
                            color: active ? Colors.primary : Colors.glassCard
                            border.width: 1
                            border.color: active ? Colors.primary : Colors.glassBorderSubtle
                            Text {
                                id: cTxt
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: active ? Font.Bold : Font.Medium
                                color: active ? Colors.m3onPrimary : Colors.m3onSurface
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: kbWin.selectedCat = modelData
                            }
                        }
                    }
                }
            }

            // 2-Column Keybind Grid
            GridView {
                id: kbGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 2
                cellHeight: 54
                clip: true
                model: kbWin.filteredBinds

                delegate: Item {
                    required property var modelData
                    width: kbGrid.cellWidth
                    height: kbGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 14
                        color: Colors.glassCard
                        border.width: 1
                        border.color: Colors.glassBorderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredHeight: 26
                                Layout.preferredWidth: Math.min(185, keyCapTxt.implicitWidth + 16)
                                radius: 8
                                color: Colors.alpha(Colors.primary, 0.20)
                                border.width: 1
                                border.color: Colors.alpha(Colors.primary, 0.45)

                                Text {
                                    id: keyCapTxt
                                    anchors.centerIn: parent
                                    text: modelData.keys
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Colors.primary
                                    elide: Text.ElideRight
                                    width: parent.width - 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Text {
                                text: modelData.desc
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Colors.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}

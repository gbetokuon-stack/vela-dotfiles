import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: clipWin
    property real openAnim: Store.clipboardOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.clipboardOpen ? 240 : 150
            easing.type: Store.clipboardOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.clipboardOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property bool onlyPinned: false
    property int selectedIndex: 0

    Connections {
        target: Store
        function onClipboardOpenChanged() {
            if (Store.clipboardOpen) {
                clipWin.query = ""
                clipWin.selectedIndex = 0
                clipSearch.text = ""
                clipSearch.forceActiveFocus()
            }
        }
    }

    readonly property var filteredItems: {
        const q = query.trim().toLowerCase()
        const list = Store.clipboardItems || []
        const out = []
        for (let i = 0; i < list.length; i++) {
            const it = list[i]
            if (onlyPinned && !it.pinned) continue
            if (q.length > 0 && !(it.preview || "").toLowerCase().includes(q)) continue
            out.push(it)
        }
        return out
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Store.clipboardOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 660
        height: 540
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: clipWin.openAnim
        scale: 0.93 + 0.07 * clipWin.openAnim
        transform: Translate { y: (1.0 - clipWin.openAnim) * 14 }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 18
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.primary }
                        GradientStop { position: 1.0; color: Colors.tertiary }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅌"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.m3onPrimary
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "Vela Clipboard Vault"
                        font.family: "Inter"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: `${clipWin.filteredItems.length} mục  ·  Enter để copy  ·  Super + V`
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 30; width: pinFiltTxt.implicitWidth + 20; radius: 15
                    color: clipWin.onlyPinned ? Colors.primary : Colors.glassCard
                    border.width: 1
                    border.color: clipWin.onlyPinned ? Colors.primary : Colors.glassBorderSubtle
                    Text {
                        id: pinFiltTxt
                        anchors.centerIn: parent
                        text: "󰐃 Đã ghim"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: clipWin.onlyPinned ? Font.Bold : Font.Medium
                        color: clipWin.onlyPinned ? Colors.m3onPrimary : Colors.m3onSurface
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipWin.onlyPinned = !clipWin.onlyPinned
                            clipWin.selectedIndex = 0
                        }
                    }
                }

                Rectangle {
                    height: 30; width: clrTxt.implicitWidth + 20; radius: 15
                    color: Colors.alpha(Colors.error, 0.18)
                    border.width: 1
                    border.color: Colors.alpha(Colors.error, 0.45)
                    Text {
                        id: clrTxt
                        anchors.centerIn: parent
                        text: "󰆴 Xóa hết"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Colors.error
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Store.clearClipboard()
                    }
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 22
                color: Colors.glassCard
                border.width: clipSearch.activeFocus ? 1.5 : 1
                border.color: clipSearch.activeFocus ? Colors.primary : Colors.glassBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.primary
                    }

                    TextInput {
                        id: clipSearch
                        Layout.fillWidth: true
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: Colors.m3onSurface
                        clip: true
                        focus: true

                        onTextChanged: {
                            clipWin.query = text
                            clipWin.selectedIndex = 0
                        }

                        Keys.onEscapePressed: Store.clipboardOpen = false
                        Keys.onDownPressed: {
                            if (clipWin.selectedIndex + 1 < clipWin.filteredItems.length) {
                                clipWin.selectedIndex += 1
                                clipList.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain)
                            }
                        }
                        Keys.onUpPressed: {
                            if (clipWin.selectedIndex > 0) {
                                clipWin.selectedIndex -= 1
                                clipList.positionViewAtIndex(clipWin.selectedIndex, ListView.Contain)
                            }
                        }
                        Keys.onReturnPressed: {
                            if (clipWin.filteredItems.length > 0) {
                                Store.copyClipboardItem(clipWin.filteredItems[clipWin.selectedIndex].id)
                                Store.clipboardOpen = false
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: parent.text.length === 0
                            text: "Tìm trong lịch sử clipboard (văn bản hoặc ảnh)..."
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: Colors.m3onSurfaceVariant
                        }
                    }
                }
            }

            // Clipboard Entries List
            ListView {
                id: clipList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                model: clipWin.filteredItems

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isSel: index === clipWin.selectedIndex

                    width: clipList.width
                    height: modelData.isImage ? 78 : 54
                    radius: 16
                    color: isSel || rowHover.containsMouse
                        ? Colors.alpha(Colors.primary, 0.20)
                        : Colors.glassCard
                    border.width: isSel ? 1.5 : 1
                    border.color: modelData.pinned
                        ? Colors.tertiary
                        : (isSel || rowHover.containsMouse ? Colors.primary : Colors.glassBorderSubtle)

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipWin.selectedIndex = index
                        onClicked: {
                            Store.copyClipboardItem(modelData.id)
                            Store.clipboardOpen = false
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Thumbnail for image or type badge
                        Rectangle {
                            width: modelData.isImage ? 92 : 34
                            height: modelData.isImage ? 58 : 34
                            radius: modelData.isImage ? 10 : 12
                            color: Colors.glassHighlight
                            clip: true

                            Image {
                                visible: modelData.isImage && (modelData.thumb || "").length > 0
                                anchors.fill: parent
                                source: modelData.thumb ? ("file://" + modelData.thumb) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Text {
                                visible: !modelData.isImage
                                anchors.centerIn: parent
                                text: modelData.pinned ? "󰐃" : "󰈚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: modelData.pinned ? Colors.tertiary : Colors.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.isImage ? "Image Snapshot" : modelData.preview
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: isSel ? Font.DemiBold : Font.Normal
                                color: Colors.m3onSurface
                                elide: Text.ElideRight
                                maximumLineCount: modelData.isImage ? 1 : 2
                                wrapMode: Text.WrapAnywhere
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: modelData.isImage || modelData.pinned
                                text: modelData.isImage ? modelData.preview : "Pinned"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: modelData.pinned ? Colors.tertiary : Colors.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Pin toggle
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: modelData.pinned ? Colors.alpha(Colors.tertiary, 0.25) : Colors.glassHighlight
                            Text {
                                anchors.centerIn: parent
                                text: "󰐃"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: modelData.pinned ? Colors.tertiary : Colors.m3onSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Store.togglePinClipboard(modelData.id)
                            }
                        }

                        // Delete item
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: Colors.glassHighlight
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 11
                                color: Colors.error
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Store.deleteClipboardItem(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

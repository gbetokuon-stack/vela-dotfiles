import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallOverlay
    property real openAnim: Store.wallpaperOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.wallpaperOpen ? 260 : 160
            easing.type: Store.wallpaperOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.wallpaperOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-wall"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.wallpaperOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var schemes: [
        { id: "scheme-tonal-spot",  label: "Tonal Spot" },
        { id: "scheme-expressive",  label: "Expressive" },
        { id: "scheme-fidelity",    label: "Fidelity" },
        { id: "scheme-vibrant",     label: "Vibrant" },
        { id: "scheme-fruit-salad", label: "Fruit Salad" },
        { id: "scheme-rainbow",     label: "Rainbow" },
        { id: "scheme-monochrome",  label: "Monochrome" }
    ]

    MouseArea {
        anchors.fill: parent
        onClicked: Store.wallpaperOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 1020)
        height: 450
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: wallOverlay.openAnim
        scale: 0.93 + 0.07 * wallOverlay.openAnim
        transform: Translate { y: (1.0 - wallOverlay.openAnim) * 14 }

        focus: Store.wallpaperOpen
        Keys.onEscapePressed: Store.wallpaperOpen = false

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            // Top Row: Title + Random Buttons + Dark/Light Toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Vela Atmosphere & Material You Studio"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Colors.m3onSurface
                    }
                    Text {
                        text: "Chọn ảnh nền, Random ảnh nền/chủ đề hoặc chuyển Dark/Light Mode"
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: Colors.m3onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                // Random Wallpaper Button
                Rectangle {
                    height: 34; width: rwRow.implicitWidth + 22; radius: 17
                    color: Colors.alpha(Colors.primary, 0.22)
                    border.width: 1; border.color: Colors.primary
                    Row {
                        id: rwRow; anchors.centerIn: parent; spacing: 6
                        Text { text: "󰒝"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Colors.primary }
                        Text { text: "Random Ảnh"; font.family: "Inter"; font.pixelSize: 12; font.bold: true; color: Colors.primary }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomWallpaper() }
                }

                // Random Wallpaper + Scheme Button
                Rectangle {
                    height: 34; width: raRow.implicitWidth + 22; radius: 17
                    color: Colors.alpha(Colors.tertiary, 0.22)
                    border.width: 1; border.color: Colors.tertiary
                    Row {
                        id: raRow; anchors.centerIn: parent; spacing: 6
                        Text { text: "🎲"; font.pixelSize: 13 }
                        Text { text: "Random Tất Cả"; font.family: "Inter"; font.pixelSize: 12; font.bold: true; color: Colors.tertiary }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.randomThemeAll() }
                }

                // Dark / Light Mode Toggle
                Rectangle {
                    height: 34; width: dlRow.implicitWidth + 22; radius: 17
                    color: Store.currentMode === "light" ? Colors.primary : Colors.glassCard
                    border.width: 1; border.color: Colors.glassBorder
                    Row {
                        id: dlRow; anchors.centerIn: parent; spacing: 6
                        Text {
                            text: Store.currentMode === "dark" ? "󰖔" : "󰖨"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            color: Store.currentMode === "light" ? Colors.m3onPrimary : Colors.tertiary
                        }
                        Text {
                            text: Store.currentMode === "dark" ? "Dark Mode" : "Light Mode"
                            font.family: "Inter"; font.pixelSize: 12; font.bold: true
                            color: Store.currentMode === "light" ? Colors.m3onPrimary : Colors.m3onSurface
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Store.toggleDarkLight() }
                }
            }

            // Second Row: 7 Matugen Color Scheme Chips
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "Bảng màu:"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: Colors.m3onSurfaceVariant
                }
                Repeater {
                    model: wallOverlay.schemes
                    delegate: Rectangle {
                        readonly property bool selected: Store.currentScheme === modelData.id
                        height: 28
                        width: schemeTxt.implicitWidth + 20
                        radius: 14
                        color: selected ? Colors.primary : Colors.glassCard
                        border.width: 1
                        border.color: selected ? Colors.primary : Colors.glassBorderSubtle

                        Text {
                            id: schemeTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: selected ? Font.Bold : Font.Medium
                            color: selected ? Colors.m3onPrimary : Colors.m3onSurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Store.applyScheme(modelData.id)
                        }
                    }
                }
            }

            // Horizontal Wallpaper Gallery
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: 16
                clip: true
                model: Store.wallpapers

                delegate: Item {
                    width: 270
                    height: 265
                    readonly property bool isCurrent: Store.currentWallpaper === modelData
                    readonly property string fileName: modelData.split("/").pop().replace(/\.[^.]+$/, "")

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: 20
                        color: Colors.glassCard
                        border.width: isCurrent ? 2 : 1
                        border.color: isCurrent ? Colors.primary : (cardHover.containsMouse ? Colors.alpha(Colors.primary, 0.55) : Colors.glassBorderSubtle)
                        scale: cardHover.containsMouse ? 1.02 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                clip: true
                                color: Colors.surfaceContainerLowest

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + modelData
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 480
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                Text {
                                    text: fileName
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: isCurrent
                                    color: isCurrent ? Colors.primary : Colors.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    visible: isCurrent
                                    text: "ACTIVE"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Colors.primary
                                }
                            }
                        }

                        MouseArea {
                            id: cardHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Store.applyWallpaper(modelData)
                        }
                    }
                }
            }
        }
    }
}

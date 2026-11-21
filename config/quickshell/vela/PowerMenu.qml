import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerOverlay
    property real openAnim: Store.powerOpen ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.powerOpen ? 240 : 150
            easing.type: Store.powerOpen ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.powerOpen || openAnim > 0.005
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    WlrLayershell.namespace: "vela-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Store.powerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var actions: [
        { icon: "󰌾", label: "Lock",     cmd: "hyprlock",                       danger: false },
        { icon: "󰤄", label: "Suspend",  cmd: "systemctl suspend",              danger: false },
        { icon: "󰍃", label: "Logout",   cmd: "hyprctl dispatch 'hl.dsp.exit()'",danger: false },
        { icon: "󰜉", label: "Reboot",   cmd: "systemctl reboot",               danger: true  },
        { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff",             danger: true  }
    ]

    MouseArea {
        anchors.fill: parent
        onClicked: Store.powerOpen = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: actionsRow.implicitWidth + 48
        height: 160
        radius: 28
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: powerOverlay.openAnim
        scale: 0.92 + 0.08 * powerOverlay.openAnim

        focus: Store.powerOpen
        Keys.onEscapePressed: Store.powerOpen = false

        RowLayout {
            id: actionsRow
            anchors.centerIn: parent
            spacing: 16

            Repeater {
                model: powerOverlay.actions
                delegate: Rectangle {
                    width: 102
                    height: 108
                    radius: 20
                    color: btnHover.containsMouse
                        ? (modelData.danger ? Colors.alpha(Colors.error, 0.28) : Colors.alpha(Colors.primary, 0.25))
                        : Colors.glassCard
                    border.width: 1
                    border.color: btnHover.containsMouse
                        ? (modelData.danger ? Colors.error : Colors.primary)
                        : Colors.glassBorderSubtle
                    scale: btnHover.containsMouse ? 1.05 : 1.0

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: modelData.danger ? Colors.error : Colors.primary
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.m3onSurface
                        }
                    }

                    MouseArea {
                        id: btnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Store.powerOpen = false
                            Store.runCmd(modelData.cmd)
                        }
                    }
                }
            }
        }
    }
}

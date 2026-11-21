import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd
    property real openAnim: Store.osdVisible ? 1.0 : 0.0
    Behavior on openAnim {
        NumberAnimation {
            duration: Store.osdVisible ? 220 : 170
            easing.type: Store.osdVisible ? Easing.OutQuint : Easing.InCubic
        }
    }
    visible: Store.osdVisible || openAnim > 0.005
    anchors {
        bottom: true
    }
    margins {
        bottom: 64
    }
    implicitWidth: 280
    implicitHeight: 58
    color: "transparent"

    WlrLayershell.namespace: "vela-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        radius: 29
        color: Colors.glassDeep
        border.width: 1
        border.color: Colors.glassBorder
        opacity: osd.openAnim
        scale: 0.90 + 0.10 * osd.openAnim
        transform: Translate { y: (1.0 - osd.openAnim) * 14 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                text: Store.osdKind === "layout"
                    ? "󰕮"
                    : (Store.osdKind === "brightness"
                        ? "󰃠"
                        : (Store.osdMuted || Store.osdValue === 0
                            ? "󰝟"
                            : (Store.activeSinkIsHeadset ? "󰋋" : (Store.osdValue > 50 ? "󰕾" : "󰖀"))))
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: Colors.primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    visible: Store.osdKind === "volume" || Store.osdKind === "layout"
                    text: Store.osdKind === "layout" ? Store.osdText : Store.activeSinkName
                    font.family: "Inter"
                    font.pixelSize: Store.osdKind === "layout" ? 11 : 10
                    font.weight: Store.osdKind === "layout" ? Font.DemiBold : Font.Medium
                    color: Store.osdKind === "layout" ? Colors.m3onSurface : Colors.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Colors.glassHighlight

                    Rectangle {
                        id: osdFill
                        readonly property bool isMutedVol: Store.osdKind === "volume" && Store.osdMuted
                        readonly property bool isBoost: Store.osdKind === "volume" && !Store.osdMuted && Store.osdValue > 100
                        readonly property real ratio: isMutedVol ? 0 : Math.max(0, Math.min(1, Store.osdValue / 100))
                        width: ratio <= 0 ? 0 : Math.max(8, parent.width * ratio)
                        height: parent.height
                        radius: 4
                        opacity: isMutedVol ? 0.35 : 1.0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: osdFill.isBoost ? Colors.tertiary : Colors.primary }
                            GradientStop { position: 1.0; color: osdFill.isBoost ? Colors.error : Colors.tertiary }
                        }
                        Behavior on width { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Text {
                text: Store.osdKind === "layout"
                    ? `${Store.osdValue}:${100 - Store.osdValue}`
                    : (Store.osdMuted ? "Muted" : `${Store.osdValue}%`)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                color: Colors.m3onSurface
                Layout.preferredWidth: 46
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

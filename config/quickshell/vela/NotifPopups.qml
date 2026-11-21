import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Widgets

Scope {
    id: notifScope

    property var activeNotifs: []

    function removeToast(nid) {
        const next = []
        for (let i = 0; i < activeNotifs.length; i++) {
            if (activeNotifs[i].nid !== nid) next.push(activeNotifs[i])
        }
        activeNotifs = next
    }

    function resolveThemeIcon(rawIcon, appName) {
        const candidates = []
        if (rawIcon && !rawIcon.startsWith("/") && !rawIcon.startsWith("file://") && !rawIcon.startsWith("image://")) {
            candidates.push(rawIcon)
        }
        const lowerApp = String(appName || "").toLowerCase()
        if (lowerApp.includes("satty") || lowerApp.includes("capture") || lowerApp.includes("screenshot")) {
            candidates.push("satty", "applets-screenshooter", "camera-photo")
        } else if (lowerApp) {
            candidates.push(lowerApp)
        }
        for (let i = 0; i < candidates.length; i++) {
            const name = candidates[i]
            if (name && Quickshell.hasThemeIcon(name)) {
                const p = Quickshell.iconPath(name, true)
                if (p && p.length > 0) return p
            }
        }
        return ""
    }

    function resolveFileImageUrl(rawImage, rawAppIcon) {
        const src = rawImage || rawAppIcon || ""
        if (!src) return ""
        if (src.startsWith("image://qsimage/")) return src
        if (src.startsWith("file://")) return src
        if (src.startsWith("/")) return "file://" + src
        return ""
    }

    function fallbackGlyph(appName, summary) {
        const s = (String(appName || "") + " " + String(summary || "")).toLowerCase()
        if (s.includes("satty") || s.includes("capture") || s.includes("screenshot") || s.includes("chụp")) return "󰄀"
        if (s.includes("theme") || s.includes("wallpaper") || s.includes("vela atmosphere")) return "󰸉"
        if (s.includes("game mode")) return "󰊗"
        if (s.includes("audio") || s.includes("volume") || s.includes("pipewire")) return "󰕾"
        if (s.includes("bluetooth")) return "󰂯"
        if (s.includes("wifi") || s.includes("network")) return "󰤨"
        return "󰂚"
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notification => {
            const isCrit = notification.urgency === NotificationUrgency.Critical
            // Always record in history so DND never loses messages
            Store.pushNotification(notification.appName, notification.summary, notification.body, isCrit)
            if (Store.dndEnabled && !isCrit) return

            notification.tracked = true
            const item = {
                nid: notification.id,
                appName: notification.appName || "System",
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                summary: notification.summary || "Notification",
                body: notification.body || "",
                critical: isCrit,
                notifObj: notification
            }
            const next = [item].concat(notifScope.activeNotifs)
            if (next.length > 4) next.length = 4
            notifScope.activeNotifs = next
        }
    }

    PanelWindow {
        visible: notifScope.activeNotifs.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: 60
            right: 14
        }
        implicitWidth: 360
        implicitHeight: notifCol.implicitHeight + 8
        color: "transparent"

        WlrLayershell.namespace: "vela-notifs"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ColumnLayout {
            id: notifCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10

            Repeater {
                model: notifScope.activeNotifs
                delegate: Rectangle {
                    id: toast
                    required property var modelData
                    readonly property var nObj: modelData.notifObj
                    // Never feed raw file paths (/tmp/.tmp...) into IconImage (image://icon/),
                    // because deleted temp files trigger Quickshell's purple-and-black missing texture!
                    readonly property string fileImgUrl: notifScope.resolveFileImageUrl(modelData.image, modelData.appIcon)
                    readonly property string themeIconUrl: notifScope.resolveThemeIcon(modelData.appIcon, modelData.appName)
                    readonly property string glyphText: notifScope.fallbackGlyph(modelData.appName, modelData.summary)

                    Layout.fillWidth: true
                    implicitHeight: toastBody.implicitHeight + 24
                    radius: 18
                    color: Colors.glassDeep
                    border.width: 1
                    border.color: modelData.critical ? Colors.error : Colors.glassBorder

                    property real enterAnim: 0.0
                    Component.onCompleted: enterAnim = 1.0
                    Behavior on enterAnim { NumberAnimation { duration: 280; easing.type: Easing.OutQuint } }
                    opacity: enterAnim
                    scale: 0.94 + 0.06 * enterAnim
                    transform: Translate { x: (1.0 - toast.enterAnim) * 24 }

                    Timer {
                        interval: modelData.critical ? 9000 : 5200
                        running: true
                        repeat: false
                        onTriggered: notifScope.removeToast(modelData.nid)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (toast.nObj) toast.nObj.dismiss()
                            notifScope.removeToast(modelData.nid)
                        }
                    }

                    RowLayout {
                        id: toastBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            width: 4
                            Layout.fillHeight: true
                            radius: 2
                            color: modelData.critical ? Colors.error : Colors.primary
                        }

                        // App Icon / Thumbnail Image / Clean Nerd Font Fallback (Zero Purple-Black Checkerboard)
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 11
                            color: Colors.glassHighlight
                            clip: true
                            Layout.alignment: Qt.AlignTop

                            Image {
                                id: fileImg
                                anchors.fill: parent
                                anchors.margins: 2
                                source: toast.fileImgUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                visible: toast.fileImgUrl.length > 0 && status === Image.Ready
                            }

                            IconImage {
                                id: themeIconImg
                                anchors.fill: parent
                                anchors.margins: 5
                                source: (!fileImg.visible && toast.themeIconUrl.length > 0) ? toast.themeIconUrl : ""
                                visible: !fileImg.visible && toast.themeIconUrl.length > 0
                                asynchronous: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !fileImg.visible && !themeIconImg.visible
                                text: toast.glyphText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: modelData.critical ? Colors.error : Colors.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.appName.toUpperCase()
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: modelData.critical ? Colors.error : Colors.primary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "✕"
                                    font.pixelSize: 11
                                    color: Colors.m3onSurfaceVariant
                                }
                            }

                            Text {
                                text: modelData.summary
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Colors.m3onSurface
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: modelData.body.length > 0
                                text: modelData.body
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: Colors.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Interactive Notification Action Buttons
                            RowLayout {
                                visible: toast.nObj && toast.nObj.actions && toast.nObj.actions.length > 0
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 6

                                Repeater {
                                    model: toast.nObj ? toast.nObj.actions : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        height: 24
                                        Layout.preferredWidth: actTxt.implicitWidth + 16
                                        radius: 10
                                        color: Colors.alpha(Colors.primary, 0.22)
                                        border.width: 1
                                        border.color: Colors.alpha(Colors.primary, 0.48)

                                        Text {
                                            id: actTxt
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: Colors.primary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                modelData.invoke()
                                                notifScope.removeToast(toast.modelData.nid)
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
}

// =============================================================================
//  VELA "NOCTURNE PRISM" — 144Hz Native Qt6 QML SDDM Login Screen
//  Zero legacy SddmComponents warnings · Hardware MultiEffect Frosted Glass
// =============================================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    width: 1920
    height: 1080

    // Theme Palette (Material You Nocturne Prism Dark)
    readonly property color colBg:        "#0c0e13"
    readonly property color colCard:      "#cc11131a"
    readonly property color colSurface:   "#dd1b1e28"
    readonly property color colSurfaceHi: "#ee252936"
    readonly property color colPrimary:   "#adc6ff"
    readonly property color colTertiary:  "#debcdf"
    readonly property color colFg:        "#e2e2e9"
    readonly property color colMuted:     "#9ca7ba"
    readonly property color colError:     "#ffb4ab"
    readonly property color colSuccess:   "#7bd89f"
    readonly property color colOutline:   "#44adc6ff"
    readonly property color colSubtle:    "#26ffffff"

    readonly property string fontSans: "Inter"
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    // Authentication & Session State
    property string currentUsername: (typeof userModel !== "undefined" && userModel && userModel.lastUser)
                                     ? userModel.lastUser : "cuongacoustic"
    property int currentSessionIndex: (typeof sessionModel !== "undefined" && sessionModel && sessionModel.lastIndex >= 0)
                                      ? sessionModel.lastIndex : 0
    property string currentSessionName: "Hyprland"
    property bool isAuthenticating: false
    property bool showPassword: false
    property string statusMessage: "Authenticate to launch 144Hz Wayland Session"
    property bool statusIsError: false
    property bool statusIsSuccess: false
    property bool sessionPopupOpen: false
    property real entranceProgress: 0.0

    // Live Clock State
    property string clockHours: Qt.formatTime(new Date(), "hh")
    property string clockMinutes: Qt.formatTime(new Date(), "mm")
    property string clockSeconds: Qt.formatTime(new Date(), "ss")
    property string clockDate: Qt.formatDate(new Date(), "dddd  ·  dd MMMM yyyy").toUpperCase()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            root.clockHours   = Qt.formatTime(now, "hh")
            root.clockMinutes = Qt.formatTime(now, "mm")
            root.clockSeconds = Qt.formatTime(now, "ss")
            root.clockDate    = Qt.formatDate(now, "dddd  ·  dd MMMM yyyy").toUpperCase()
        }
    }

    // Hidden Repeater to sync session names from SDDM's sessionModel
    ListModel {
        id: fallbackSessions
        ListElement { name: "Hyprland" }
        ListElement { name: "Hyprland (uwsm-managed)" }
    }

    property var activeSessionModel: (typeof sessionModel !== "undefined" && sessionModel) ? sessionModel : fallbackSessions

    Repeater {
        id: sessionSynchronizer
        model: root.activeSessionModel
        delegate: Item {
            required property int index
            required property string name
            Component.onCompleted: {
                if (index === root.currentSessionIndex) {
                    root.currentSessionName = name
                }
            }
            Connections {
                target: root
                function onCurrentSessionIndexChanged() {
                    if (index === root.currentSessionIndex) {
                        root.currentSessionName = name
                    }
                }
            }
        }
    }

    function cycleSession() {
        var cnt = sessionSynchronizer.count
        if (cnt > 0) {
            root.currentSessionIndex = (root.currentSessionIndex + 1) % cnt
        }
    }

    function performLogin() {
        if (root.isAuthenticating) return
        root.isAuthenticating = true
        root.statusIsError = false
        root.statusIsSuccess = false
        root.statusMessage = "Initializing Hyprland 0.57 Wayland Compositor..."
        if (typeof sddm !== "undefined" && sddm) {
            sddm.login(userField.text, passField.text, root.currentSessionIndex)
        } else {
            testLoginTimer.start()
        }
    }

    Timer {
        id: testLoginTimer
        interval: 900
        repeat: false
        onTriggered: {
            root.isAuthenticating = false
            if (passField.text.length > 0) {
                root.statusIsSuccess = true
                root.statusMessage = "Session Verified · Launching Hyprland 144Hz..."
            } else {
                root.statusIsError = true
                root.statusMessage = "Authentication failed · Please enter passphrase"
                shakeAnim.restart()
            }
        }
    }

    Connections {
        target: (typeof sddm !== "undefined" && sddm) ? sddm : null

        function onLoginSucceeded() {
            root.isAuthenticating = false
            root.statusIsError = false
            root.statusIsSuccess = true
            root.statusMessage = "Welcome back · Launching Hyprland 144Hz..."
            unlockZoomAnim.restart()
        }

        function onLoginFailed() {
            root.isAuthenticating = false
            root.statusIsError = true
            root.statusIsSuccess = false
            root.statusMessage = "Authentication failed · Please check passphrase"
            passField.text = ""
            passField.forceActiveFocus()
            shakeAnim.restart()
        }

        function onInformationMessage(message) {
            root.isAuthenticating = false
            root.statusIsError = true
            root.statusMessage = message
        }
    }

    Component.onCompleted: {
        entranceAnim.start()
        passField.forceActiveFocus()
    }

    NumberAnimation {
        id: entranceAnim
        target: root
        property: "entranceProgress"
        from: 0.0
        to: 1.0
        duration: 680
        easing.type: Easing.OutQuint
    }

    ParallelAnimation {
        id: unlockZoomAnim
        NumberAnimation { target: mainContent; property: "opacity"; to: 0.0; duration: 340; easing.type: Easing.InCubic }
        NumberAnimation { target: mainContent; property: "scale"; to: 1.06; duration: 340; easing.type: Easing.InCubic }
    }

    // =========================================================================
    // 1. LAYERED WALLPAPER &HARDWARE-BLURRED AMBIENT AURORA BACKDROP
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        color: root.colBg
    }

    Image {
        id: wallImage
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
        scale: 1.08 - (0.04 * root.entranceProgress)
        visible: false
    }

    MultiEffect {
        id: wallBlurred
        anchors.fill: parent
        source: wallImage
        blurEnabled: true
        blurMax: 52
        blur: 0.72
        brightness: -0.22
        contrast: 0.10
        saturation: 0.22
    }

    // Dark Obsidian Vignette Overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#a8080a0f" }
            GradientStop { position: 0.5; color: "#720c0e13" }
            GradientStop { position: 1.0; color: "#c807090d" }
        }
    }

    // Floating Ambient Nocturne Prism Orbs (144Hz Breathing Glow)
    Item {
        anchors.fill: parent
        opacity: 0.55 * root.entranceProgress

        Rectangle {
            id: orbPrimary
            width: 520
            height: 520
            radius: 260
            x: parent.width * 0.22
            y: parent.height * 0.16
            color: "#22adc6ff"
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 64
                blur: 1.0
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: root.width * 0.30; duration: 6400; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.width * 0.22; duration: 6400; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: root.height * 0.24; duration: 5200; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.height * 0.16; duration: 5200; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: orbTertiary
            width: 480
            height: 480
            radius: 240
            x: parent.width * 0.55
            y: parent.height * 0.45
            color: "#1edebcdf"
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 64
                blur: 1.0
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: root.width * 0.48; duration: 7000; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.width * 0.55; duration: 7000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: root.height * 0.36; duration: 5800; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.height * 0.45; duration: 5800; easing.type: Easing.InOutSine }
            }
        }
    }

    // =========================================================================
    // 2. MAIN HUD CONTAINER
    // =========================================================================
    Item {
        id: mainContent
        anchors.fill: parent
        opacity: root.entranceProgress
        scale: 0.96 + (0.04 * root.entranceProgress)

        // ---------------------------------------------------------------------
        // A. TOP STATUS CAPSULE
        // ---------------------------------------------------------------------
        Rectangle {
            id: topCapsule
            width: topRow.implicitWidth + 44
            height: 44
            radius: 22
            anchors.top: parent.top
            anchors.topMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.colCard
            border.width: 1
            border.color: root.colOutline

            RowLayout {
                id: topRow
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: "󰣇  VICTUS ARCH"
                    color: root.colPrimary
                    font.family: root.fontMono
                    font.pixelSize: 12
                    font.bold: true
                }

                Text { text: "·"; color: root.colMuted; font.pixelSize: 14 }

                Text {
                    text: "󰖲  HYPRLAND 0.57.2"
                    color: root.colFg
                    font.family: root.fontMono
                    font.pixelSize: 12
                    font.bold: true
                }

                Text { text: "·"; color: root.colMuted; font.pixelSize: 14 }

                Text {
                    text: "󰍹  144Hz VRR WAYLAND"
                    color: root.colTertiary
                    font.family: root.fontMono
                    font.pixelSize: 12
                    font.bold: true
                }

                Rectangle {
                    visible: (typeof keyboard !== "undefined" && keyboard && keyboard.capsLock)
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: capsText.implicitWidth + 18
                    radius: 12
                    color: "#33ffb4ab"
                    border.width: 1
                    border.color: root.colError

                    Text {
                        id: capsText
                        anchors.centerIn: parent
                        text: "󰪛 CAPS LOCK"
                        color: root.colError
                        font.family: root.fontMono
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // B. SCULPTURAL DUAL-TONE EDITORIAL CLOCK & DATE HUD
        // ---------------------------------------------------------------------
        ColumnLayout {
            id: clockSection
            anchors.top: topCapsule.bottom
            anchors.topMargin: 38
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Text {
                    text: root.clockHours
                    color: root.colPrimary
                    font.family: root.fontSans
                    font.pixelSize: 128
                    font.weight: Font.Black
                }

                Text {
                    id: colonLabel
                    text: ":"
                    color: root.colTertiary
                    font.family: root.fontSans
                    font.pixelSize: 104
                    font.weight: Font.Light
                    Layout.alignment: Qt.AlignVCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: root.clockMinutes
                    color: root.colFg
                    font.family: root.fontSans
                    font.pixelSize: 128
                    font.weight: Font.Light
                }
            }

            // Date Pill
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: dateText.implicitWidth + 44
                height: 36
                radius: 18
                color: root.colSurface
                border.width: 1
                border.color: root.colOutline

                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: "◆   " + root.clockDate + "  ·  " + root.clockSeconds + "s   ◆"
                    color: root.colPrimary
                    font.family: root.fontMono
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // ---------------------------------------------------------------------
        // C. CENTER FROSTED OBSIDIAN-GLASS AUTHENTICATION DECK
        // ---------------------------------------------------------------------
        Rectangle {
            id: authDeck
            width: 470
            height: 318
            radius: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 76
            color: root.colCard
            border.width: passField.activeFocus ? 1.5 : 1
            border.color: root.statusIsError ? root.colError
                        : root.statusIsSuccess ? root.colSuccess
                        : passField.activeFocus ? root.colPrimary : root.colOutline

            property real shakeOffset: 0
            transform: Translate { x: authDeck.shakeOffset }

            Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: authDeck; property: "shakeOffset"; to: -16; duration: 48; easing.type: Easing.OutQuad }
                NumberAnimation { target: authDeck; property: "shakeOffset"; to: 15;  duration: 58; easing.type: Easing.InOutQuad }
                NumberAnimation { target: authDeck; property: "shakeOffset"; to: -11; duration: 54; easing.type: Easing.InOutQuad }
                NumberAnimation { target: authDeck; property: "shakeOffset"; to: 7;   duration: 48; easing.type: Easing.InOutQuad }
                NumberAnimation { target: authDeck; property: "shakeOffset"; to: 0;   duration: 45; easing.type: Easing.OutBounce }
            }

            // Top Subtle Specular Highlight Bar
            Rectangle {
                width: parent.width * 0.52
                height: 2
                radius: 1
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.colPrimary }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                // Avatar Ring & Geometric Nocturne Emblem
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 68
                    height: 68

                    Rectangle {
                        anchors.fill: parent
                        radius: 34
                        color: "transparent"
                        border.width: 1
                        border.color: root.colOutline

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.08; duration: 1800; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.00; duration: 1800; easing.type: Easing.InOutSine }
                        }
                    }

                    Rectangle {
                        width: 56
                        height: 56
                        radius: 28
                        anchors.centerIn: parent
                        color: root.colSurface
                        border.width: 2
                        border.color: root.statusIsError ? root.colError
                                    : root.statusIsSuccess ? root.colSuccess
                                    : root.colPrimary

                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.statusIsSuccess ? "󰄬" : root.statusIsError ? "󰀨" : "◆"
                            color: root.statusIsError ? root.colError
                                 : root.statusIsSuccess ? root.colSuccess
                                 : root.colPrimary
                            font.family: root.fontMono
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }

                // Editable / Interactive Username Pill
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 260
                    height: 34
                    radius: 17
                    color: userField.activeFocus ? root.colSurfaceHi : "transparent"
                    border.width: userField.activeFocus ? 1 : 0
                    border.color: root.colPrimary

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰀄"
                            color: root.colPrimary
                            font.family: root.fontMono
                            font.pixelSize: 13
                        }

                        TextInput {
                            id: userField
                            text: root.currentUsername
                            color: root.colFg
                            font.family: root.fontSans
                            font.pixelSize: 15
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            KeyNavigation.tab: passField
                            Keys.onReturnPressed: passField.forceActiveFocus()
                            Keys.onEnterPressed: passField.forceActiveFocus()
                        }

                        Text {
                            text: "·  STUDIO"
                            color: root.colMuted
                            font.family: root.fontMono
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                // Status Subtitle
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (root.statusIsError ? "󰀨  " : root.statusIsSuccess ? "󰄬  " : "󰌾  ") + root.statusMessage
                    color: root.statusIsError ? root.colError
                         : root.statusIsSuccess ? root.colSuccess
                         : root.colMuted
                    font.family: root.fontMono
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                // Passphrase Input Pill
                Rectangle {
                    id: passBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 26
                    color: passField.activeFocus ? root.colSurfaceHi : root.colSurface
                    border.width: passField.activeFocus ? 2 : 1
                    border.color: root.statusIsError ? root.colError
                                : passField.activeFocus ? root.colPrimary : root.colOutline

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 8
                        spacing: 10

                        Text {
                            text: "󰌆"
                            color: passField.activeFocus ? root.colPrimary : root.colMuted
                            font.family: root.fontMono
                            font.pixelSize: 16
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Enter passphrase..."
                                color: root.colMuted
                                opacity: passField.text.length === 0 ? 0.72 : 0.0
                                font.family: root.fontSans
                                font.pixelSize: 14
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            TextInput {
                                id: passField
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                color: root.colFg
                                font.family: root.fontMono
                                font.pixelSize: 15
                                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "●"
                                focus: true
                                clip: true
                                selectByMouse: true
                                KeyNavigation.tab: userField
                                Keys.onReturnPressed: root.performLogin()
                                Keys.onEnterPressed: root.performLogin()
                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_F2) {
                                        root.cycleSession()
                                        event.accepted = true
                                    }
                                }
                            }
                        }

                        // Show/Hide Passphrase Toggle Button
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: eyeMouse.containsMouse ? "#22ffffff" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.showPassword ? "󰈉" : "󰈈"
                                color: root.showPassword ? root.colTertiary : root.colMuted
                                font.family: root.fontMono
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.showPassword = !root.showPassword
                                    passField.forceActiveFocus()
                                }
                            }
                        }

                        // Submit Arrow Pill Button
                        Rectangle {
                            id: submitBtn
                            width: 38
                            height: 38
                            radius: 19
                            color: submitMouse.containsMouse ? root.colTertiary : root.colPrimary
                            scale: submitMouse.pressed ? 0.92 : submitMouse.containsMouse ? 1.06 : 1.0

                            Behavior on color { ColorAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: root.isAuthenticating ? "󰔟" : "󰁔"
                                color: "#0b0e14"
                                font.family: root.fontMono
                                font.pixelSize: 17
                                font.bold: true
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.performLogin()
                            }
                        }
                    }
                }

                // Interactive Session Selector Pill inside Auth Card
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: sessionRow.implicitWidth + 32
                    height: 32
                    radius: 16
                    color: sessMouse.containsMouse ? root.colSurfaceHi : root.colSurface
                    border.width: 1
                    border.color: sessMouse.containsMouse ? root.colPrimary : root.colSubtle

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: sessionRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰖲  Session:"
                            color: root.colMuted
                            font.family: root.fontMono
                            font.pixelSize: 11
                        }

                        Text {
                            text: root.currentSessionName
                            color: root.colPrimary
                            font.family: root.fontSans
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: "󰁯  (Click / F2)"
                            color: root.colTertiary
                            font.family: root.fontMono
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: sessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.cycleSession()
                            passField.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // D. BOTTOM 3-CARD BENTO DOCK (TELEMETRY · HOST · POWER ACTIONS)
        // ---------------------------------------------------------------------
        RowLayout {
            id: bottomDock
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            // Card 1: Silicon Telemetry
            Rectangle {
                Layout.preferredWidth: 290
                Layout.preferredHeight: 74
                radius: 22
                color: root.colCard
                border.width: 1
                border.color: root.colOutline

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰻠  SILICON TELEMETRY"
                        color: root.colPrimary
                        font.family: root.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Ryzen 7 7445HS  ·  RTX 4050"
                        color: root.colFg
                        font.family: root.fontSans
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Radeon 740M Primary  ·  144Hz VRR"
                        color: root.colMuted
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            // Card 2: Workstation & Keyboard Info
            Rectangle {
                Layout.preferredWidth: 270
                Layout.preferredHeight: 74
                radius: 22
                color: root.colCard
                border.width: 1
                border.color: root.colOutline

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰌌  WORKSTATION NODE"
                        color: root.colTertiary
                        font.family: root.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: ((typeof sddm !== "undefined" && sddm && sddm.hostName) ? sddm.hostName : "archlinux") + "  ·  Wayland"
                        color: root.colFg
                        font.family: root.fontSans
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Layout: US  ·  Aquamarine DRM"
                        color: root.colMuted
                        font.family: root.fontMono
                        font.pixelSize: 10
                    }
                }
            }

            // Card 3: Interactive Power Controls (Suspend · Reboot · Power Off)
            Rectangle {
                Layout.preferredWidth: 310
                Layout.preferredHeight: 74
                radius: 22
                color: root.colCard
                border.width: 1
                border.color: root.colOutline

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    // Suspend Button
                    Rectangle {
                        width: 84
                        height: 46
                        radius: 16
                        color: suspMouse.containsMouse ? root.colSurfaceHi : root.colSurface
                        border.width: 1
                        border.color: suspMouse.containsMouse ? root.colPrimary : root.colSubtle
                        scale: suspMouse.pressed ? 0.94 : suspMouse.containsMouse ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰤄"; color: root.colPrimary; font.family: root.fontMono; font.pixelSize: 14 }
                            Text { text: "Sleep"; color: root.colFg; font.family: root.fontSans; font.pixelSize: 11; font.bold: true }
                        }

                        MouseArea {
                            id: suspMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (typeof sddm !== "undefined" && sddm) sddm.suspend()
                        }
                    }

                    // Reboot Button
                    Rectangle {
                        width: 90
                        height: 46
                        radius: 16
                        color: rebMouse.containsMouse ? root.colSurfaceHi : root.colSurface
                        border.width: 1
                        border.color: rebMouse.containsMouse ? root.colTertiary : root.colSubtle
                        scale: rebMouse.pressed ? 0.94 : rebMouse.containsMouse ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰜉"; color: root.colTertiary; font.family: root.fontMono; font.pixelSize: 14 }
                            Text { text: "Reboot"; color: root.colFg; font.family: root.fontSans; font.pixelSize: 11; font.bold: true }
                        }

                        MouseArea {
                            id: rebMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (typeof sddm !== "undefined" && sddm) sddm.reboot()
                        }
                    }

                    // Power Off Button
                    Rectangle {
                        width: 86
                        height: 46
                        radius: 16
                        color: powMouse.containsMouse ? "#33ffb4ab" : root.colSurface
                        border.width: 1
                        border.color: powMouse.containsMouse ? root.colError : root.colSubtle
                        scale: powMouse.pressed ? 0.94 : powMouse.containsMouse ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰐥"; color: root.colError; font.family: root.fontMono; font.pixelSize: 14 }
                            Text { text: "Power"; color: root.colFg; font.family: root.fontSans; font.pixelSize: 11; font.bold: true }
                        }

                        MouseArea {
                            id: powMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (typeof sddm !== "undefined" && sddm) sddm.powerOff()
                        }
                    }
                }
            }
        }
    }
}

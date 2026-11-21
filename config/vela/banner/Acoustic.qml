// Vela Acoustic 3D Slanted Chrome + Frosted Neon Blur Renderer (Native 1:1 Full-Word Canvas)
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

Window {
    id: win
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint

    readonly property var argv: Qt.application.arguments
    function arg(name, def) {
        const i = argv.indexOf("--" + name)
        return (i >= 0 && i + 1 < argv.length) ? argv[i + 1] : def
    }

    property color primary: arg("primary", "#8ee5ff")
    property color tertiary: arg("tertiary", "#cbb9f5")
    property color secondary: arg("secondary", "#b3c8d6")
    property color deep: arg("bg", "#090c10")
    property string outFile: arg("out", "/tmp/vela-acoustic.png")
    property string label: arg("text", "Acoustic")
    property string family: arg("font", "Inter")

    readonly property int fontPx: 88
    readonly property real shear: 0.28          // pronounced 3D italic slant ("nghieng nghieng")
    readonly property int depth: 15             // 3D perspective extrusion depth
    readonly property int padX: 38
    readonly property int padY: 20

    width: Math.ceil(face.implicitWidth + fontPx * shear + depth * 1.2 + padX * 2)
    height: Math.ceil(face.implicitHeight + depth * 1.4 + padY * 2)

    function mixc(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
    }

    Item {
        id: scene
        anchors.fill: parent

        // 1. Ambient Dual-Tone Frosted Neon Blur Halo
        Item {
            id: auraSource
            anchors.fill: parent
            visible: false

            Rectangle {
                x: win.padX * 0.6
                y: win.padY * 0.7
                width: win.width * 0.50
                height: win.height * 0.60
                radius: height / 2
                color: Qt.rgba(win.primary.r, win.primary.g, win.primary.b, 0.46)
            }

            Rectangle {
                x: win.width * 0.40
                y: win.padY * 0.65
                width: win.width * 0.50
                height: win.height * 0.62
                radius: height / 2
                color: Qt.rgba(win.tertiary.r, win.tertiary.g, win.tertiary.b, 0.44)
            }
        }

        FastBlur {
            anchors.fill: parent
            source: auraSource
            radius: 44
            transparentBorder: true
            opacity: 0.90
        }

        // 2. Main 3D Extruded + Slanted Text Source
        Item {
            id: art
            anchors.fill: parent
            visible: false

            Item {
                id: sheared
                anchors.fill: parent
                transform: Matrix4x4 {
                    readonly property real cy: win.padY + face.implicitHeight * 0.72
                    matrix: Qt.matrix4x4(1, -win.shear, 0, win.shear * cy,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }

                // 3D Extrusion Stack (back-to-front)
                Repeater {
                    model: win.depth
                    delegate: Text {
                        readonly property int lyr: win.depth - index
                        readonly property real t: lyr / win.depth
                        x: win.padX + lyr * 0.95
                        y: win.padY + lyr * 1.10
                        text: win.label
                        font.family: win.family
                        font.pixelSize: win.fontPx
                        font.weight: Font.Black
                        font.italic: true
                        font.letterSpacing: -2.5
                        color: {
                            const sideTone = win.mixc(win.primary, win.tertiary, 0.45)
                            const shaded = win.mixc(sideTone, win.deep, 0.32 + t * 0.48)
                            return Qt.darker(shaded, 1.30 + t * 1.40)
                        }
                    }
                }

                // Luminous Bevel Rim Highlight
                Text {
                    x: win.padX + 1.2
                    y: win.padY + 1.4
                    text: win.label
                    font: face.font
                    color: win.mixc(win.primary, "white", 0.58)
                    opacity: 0.94
                }

                // Front Glyph Mask
                Text {
                    id: face
                    x: win.padX
                    y: win.padY
                    text: win.label
                    font.family: win.family
                    font.pixelSize: win.fontPx
                    font.weight: Font.Black
                    font.italic: true
                    font.letterSpacing: -2.5
                    color: "white"
                    visible: false
                }

                // Metallic Horizontal Gradient across Front Face
                LinearGradient {
                    anchors.fill: face
                    source: face
                    start: Qt.point(0, 0)
                    end: Qt.point(face.width, face.height * 0.30)
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: win.mixc(win.primary, "white", 0.28) }
                        GradientStop { position: 0.48; color: win.mixc(win.primary, win.tertiary, 0.48) }
                        GradientStop { position: 1.00; color: win.mixc(win.tertiary, "white", 0.22) }
                    }
                }

                // Chrome Specular Horizon Reflection
                LinearGradient {
                    anchors.fill: face
                    source: face
                    start: Qt.point(0, face.height * 0.16)
                    end: Qt.point(0, face.height * 0.90)
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.74) }
                        GradientStop { position: 0.44; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.49; color: Qt.rgba(0, 0, 0, 0.34) }
                        GradientStop { position: 0.78; color: Qt.rgba(0, 0, 0, 0.04) }
                        GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.34) }
                    }
                }
            }
        }

        // 3. Frosted Motion-Blur Ghost Layer behind the 3D block
        FastBlur {
            x: 6
            y: 5
            width: art.width
            height: art.height
            source: art
            radius: 24
            transparentBorder: true
            opacity: 0.78
        }

        // 4. Crisp 3D Slanted Chrome Layer on Top
        ShaderEffectSource {
            anchors.fill: art
            sourceItem: art
            hideSource: false
        }

        // 5. Soft Frosted Rim Blur Overlay
        FastBlur {
            anchors.fill: art
            source: art
            radius: 10
            transparentBorder: true
            opacity: 0.24
        }
    }

    Timer {
        interval: 350
        running: true
        onTriggered: {
            scene.grabToImage(function (res) {
                res.saveToFile(win.outFile)
                console.log("VELA_RENDER_OK")
                Qt.quit()
            })
        }
    }
}

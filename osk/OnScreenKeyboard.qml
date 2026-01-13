import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        id: oskWindow

        // -- 1. Dimensions --
        property real currentW: 900
        property real currentH: 350

        implicitWidth: currentW
        implicitHeight: currentH

        visible: true

        // Constraints
        property int minWidth: 600
        property int minHeight: 250

        // -- 2. Layer Shell Config --
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "standalone-osk"
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrLayerKeyboardFocus.None

        // -- 3. Positioning --
        anchors {
            top: true
            left: true
        }

        // Start Position: Bottom-Center
        property int xOffset: ((Screen.width || 1920) - currentW) / 2
        property int yOffset: ((Screen.height || 1080) - currentH - 20)

        margins {
            left: oskWindow.xOffset
            top: oskWindow.yOffset
        }

        color: "transparent"

        // -- 4. Main Background --
        Rectangle {
            id: bg
            anchors.fill: parent
            color: "#11111b"
            radius: 24
            border.color: "#333333"
            border.width: 1
            clip: true

            // -- A. WINDOW MOVING --
            DragHandler {
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                property real startX: 0
                property real startY: 0
                onActiveChanged: {
                    if (active) {
                        startX = oskWindow.xOffset
                        startY = oskWindow.yOffset
                    }
                }
                onTranslationChanged: {
                    oskWindow.xOffset = startX + translation.x
                    oskWindow.yOffset = startY + translation.y
                }
            }

            // -- B. KEYBOARD CONTENT --
            Item {
                id: contentWrapper
                anchors.centerIn: parent

                // Get intrinsic size
                width: oskContentItem.implicitWidth
                height: oskContentItem.implicitHeight

                // Uniform Scaling
                readonly property real scaleX: oskWindow.currentW / width
                readonly property real scaleY: oskWindow.currentH / height
                scale: Math.min(scaleX, scaleY) * 0.90

                transformOrigin: Item.Center
                z: 10

                OskContent {
                    id: oskContentItem
                    anchors.centerIn: parent
                }
            }

            // -- C. CLOSE BUTTON --
            Rectangle {
                width: 28; height: 28; radius: 14
                color: closeHandler.pressed ? "#ff5555" : "#333333"
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: 14
                z: 20
                Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.bold: true }
                TapHandler { id: closeHandler; onTapped: Qt.quit() }
            }

            // -- D. RESIZE HANDLE (Aspect Ratio Locked) --
            Rectangle {
                width: 40; height: 40
                color: "transparent"
                anchors.bottom: parent.bottom; anchors.right: parent.right
                z: 30

                Canvas {
                    anchors.fill: parent; anchors.margins: 12
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.strokeStyle = "#888888"; ctx.lineWidth = 3;
                        ctx.beginPath();
                        ctx.moveTo(width, height - 12);
                        ctx.lineTo(width, height);
                        ctx.lineTo(width - 12, height);
                        ctx.stroke();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeFDiagCursor
                    preventStealing: true

                    property point lastGlobalPos: Qt.point(0, 0)

                    onPressed: (mouse) => {
                        lastGlobalPos = mapToItem(null, mouse.x, mouse.y)
                    }

                    onPositionChanged: (mouse) => {
                        var globalPos = mapToItem(null, mouse.x, mouse.y)
                        var deltaX = globalPos.x - lastGlobalPos.x
                        var deltaY = globalPos.y - lastGlobalPos.y

                        var newW = oskWindow.currentW + deltaX
                        var newH = oskWindow.currentH + deltaY

                        // 1. Min constraints
                        newW = Math.max(oskWindow.minWidth, newW)
                        newH = Math.max(oskWindow.minHeight, newH)

                        // 2. ASPECT RATIO LOCK (Horizontal & Vertical)
                        var contentRatio = oskContentItem.implicitWidth / oskContentItem.implicitHeight
                        var buffer = 60 // Margin buffer

                        // Calculate max allowed sizes based on the OTHER dimension
                        var allowedH = (newW / contentRatio) + buffer
                        var allowedW = (newH * contentRatio) + buffer

                        // Stop vertical stretch (Black bars on top/bottom)
                        if (newH > allowedH) newH = allowedH

                            // Stop horizontal stretch (Black bars on left/right)
                            if (newW > allowedW) newW = allowedW

                                oskWindow.currentW = newW
                                oskWindow.currentH = newH

                                lastGlobalPos = globalPos
                    }
                }
            }
        }
    }
}

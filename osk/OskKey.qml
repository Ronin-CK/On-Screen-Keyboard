import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // -- Data --
    property var keyData: ({})
    property int keycode: keyData.keycode || 0
    property string shape: keyData.shape || "normal"

    // -- INCOMING STATES --
    property int currentShiftState: 0
    property int currentCtrlState: 0
    property int currentAltState: 0
    property bool isCapsLockActive: false

    // -- COMPUTED HELPERS --
    readonly property bool isShiftActive: currentShiftState > 0
    readonly property bool isCtrlActive:  currentCtrlState > 0
    readonly property bool isAltActive:   currentAltState > 0

    // Key Type Detection
    readonly property bool isShiftKey: keycode === 42 || keycode === 54
    readonly property bool isCtrlKey:  keycode === 29 || keycode === 97
    readonly property bool isAltKey:   keycode === 56 || keycode === 100
    readonly property bool isCapsKey:  keycode === 58
    readonly property bool isModKey:   isShiftKey || isCtrlKey || isAltKey || isCapsKey

    // Is this a letter? (Regex check: is it a single character a-z?)
    readonly property bool isLetter: keyData.label && keyData.label.toString().match(/^[a-z]$/)

    // -- THE CAPITALIZATION LOGIC --
    // We apply Shift if:
    // 1. Shift is physically active
    // 2. OR CapsLock is on AND it's a letter
    // 3. XOR (If both are on, they cancel out to lowercase)
    readonly property bool effectiveShift: isShiftActive !== (isCapsLockActive && isLetter)

    // Visual State
    readonly property int myState: isShiftKey ? currentShiftState :
    isCtrlKey  ? currentCtrlState :
    isAltKey   ? currentAltState : 0

    // Highlight Caps Lock when Active
    readonly property bool isLocked: myState === 2 || (isCapsKey && isCapsLockActive)
    readonly property bool isActive: myState > 0

    // Signals
    signal requestCycleShift()
    signal requestCycleCtrl()
    signal requestCycleAlt()
    signal requestToggleCapsLock()
    signal requestResetModifiers()

    // -- Dimensions --
    property real baseWidth: 50
    property real baseHeight: 50
    property var widthMultiplier: ({
        "normal": 1, "fn": 1, "tab": 1.5, "caps": 1.8,
        "shift": 2.4, "space": 6, "enter": 2, "expand": 1, "empty": 1, "control": 1.5
    })

    implicitWidth: baseWidth * (widthMultiplier[shape] || 1)
    implicitHeight: baseHeight
    Layout.fillWidth: shape === "expand" || shape === "space"

    readonly property bool isSpecial: shape !== "normal" && shape !== "space"

    // -- Visual Container --
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2

        color: root.isLocked ? "#cba6f7" :
        (tapHandler.pressed || root.isActive) ? "#89b4fa" :
        (root.isSpecial ? "#45475a" : "#313244")

        border.color: root.isLocked ? "#f5c2e7" : (tapHandler.pressed ? "transparent" : "#1e1e2e")
        border.width: root.isLocked ? 2 : 1
        scale: tapHandler.pressed ? 0.90 : 1.0

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on scale { NumberAnimation { duration: 50 } }

        // -- Text Label --
        Text {
            anchors.centerIn: parent

            // VISUAL: Use effectiveShift to decide whether to show "A" or "a"
            text: (root.effectiveShift && root.keyData.labelShift)
            ? root.keyData.labelShift
            : (root.keyData.label || "")

            color: (tapHandler.pressed || root.isActive || root.isLocked) ? "#11111b" : "#cdd6f4"

            font.pixelSize: Math.min(parent.height * 0.40, parent.width * 0.40)
            font.bold: root.isLocked
            font.family: "Sans Serif"
            visible: shape !== "empty"
        }
    }

    // -- Logic --
    TapHandler {
        id: tapHandler
        enabled: root.shape !== "empty"
        onTapped: root.handlePress()
    }

    Timer {
        id: repeatTimer
        interval: 100
        repeat: true
        running: tapHandler.pressed && root.keycode === 14 // Backspace
        onTriggered: root.handlePress()
    }

    function handlePress() {
        if (root.keycode <= 0) return;

        // 1. Handle Modifiers
        if (root.isModKey) {
            if (root.isShiftKey) root.requestCycleShift();
            if (root.isCtrlKey)  root.requestCycleCtrl();
            if (root.isAltKey)   root.requestCycleAlt();
            if (root.isCapsKey)  root.requestToggleCapsLock();
            return;
        }

        // 2. Build Command
        var seq = []

        // Push Modifiers DOWN
        if (root.isCtrlActive)  seq.push("29:1");
        if (root.isAltActive)   seq.push("56:1");

        // Use EFFECTIVE SHIFT (Includes Caps Logic)
        if (root.effectiveShift) seq.push("42:1");

        // The Key
        seq.push(String(root.keycode) + ":1");
        seq.push(String(root.keycode) + ":0");

        // Push Modifiers UP
        if (root.effectiveShift) seq.push("42:0");
        if (root.isAltActive)   seq.push("56:0");
        if (root.isCtrlActive)  seq.push("29:0");

        seq.unshift("key")
        seq.unshift("ydotool")

        keyPress.command = seq
        keyPress.running = true

        root.requestResetModifiers()
    }

    Process {
        id: keyPress
    }
}

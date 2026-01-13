import QtQuick
import QtQuick.Layouts
import "layouts.js" as Layouts

Item {
    id: oskContentRoot
    property var layouts: Layouts.byName
    property string activeLayoutName: "English (US)"

    // -- STATES --
    property int shiftState: 0
    property int ctrlState: 0
    property int altState: 0
    // NEW: Caps Lock State (Boolean)
    property bool capsLockState: false

    property var currentLayout: layouts[activeLayoutName] || { keys: [] }

    implicitWidth: keyRows.implicitWidth
    implicitHeight: keyRows.implicitHeight

    ColumnLayout {
        id: keyRows
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: oskContentRoot.currentLayout.keys
            delegate: RowLayout {
                required property var modelData
                spacing: 8

                Repeater {
                    model: parent.modelData
                    delegate: OskKey {
                        keyData: modelData

                        // Pass States Down
                        currentShiftState: oskContentRoot.shiftState
                        currentCtrlState: oskContentRoot.ctrlState
                        currentAltState: oskContentRoot.altState
                        // Pass Caps Lock
                        isCapsLockActive: oskContentRoot.capsLockState

                        // -- HANDLERS --
                        onRequestCycleShift: oskContentRoot.shiftState = cycleState(oskContentRoot.shiftState)
                        onRequestCycleCtrl:  oskContentRoot.ctrlState  = cycleState(oskContentRoot.ctrlState)
                        onRequestCycleAlt:   oskContentRoot.altState   = cycleState(oskContentRoot.altState)

                        // NEW: Toggle Caps Lock
                        onRequestToggleCapsLock: oskContentRoot.capsLockState = !oskContentRoot.capsLockState

                        // Reset One-Shot Modifiers
                        onRequestResetModifiers: {
                            if (oskContentRoot.shiftState === 1) oskContentRoot.shiftState = 0
                                if (oskContentRoot.ctrlState === 1)  oskContentRoot.ctrlState = 0
                                    if (oskContentRoot.altState === 1)   oskContentRoot.altState = 0
                        }
                    }
                }
            }
        }
    }

    function cycleState(current) { return (current + 1) % 3 }
}

import QtQuick
import qs.config

Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property alias echoMode: input.echoMode

    signal accepted()
    signal upPressed()
    signal downPressed()

    function focusInput() {
        input.forceActiveFocus()
    }

    implicitWidth: 160
    implicitHeight: 22

    Bevel {
        anchors.fill: parent
        sunken: true
        faceColor: Theme.field
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.text
        selectionColor: Theme.selection
        selectedTextColor: Theme.selectionText
        onAccepted: root.accepted()
        Keys.onUpPressed: root.upPressed()
        Keys.onDownPressed: root.downPressed()
        Keys.onTabPressed: root.downPressed()
        Keys.onBacktabPressed: root.upPressed()

        cursorDelegate: Rectangle {
            width: 7
            color: Theme.text
            visible: input.activeFocus

            SequentialAnimation on opacity {
                running: input.activeFocus
                loops: Animation.Infinite
                PropertyAction { value: 0.8 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 530 }
            }
        }
    }

    BarText {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.textMuted
    }
}

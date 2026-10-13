import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

Item {
    id: root

    property string text
    property string icon: ""
    property string hint: ""
    property int checkType: 0
    property bool checked: false
    property bool reserveCheck: checkType !== 0
    property bool highlighted: false
    property bool bold: false

    readonly property alias hovered: mouse.containsMouse
    readonly property bool lit: enabled && (hovered || highlighted)

    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 20
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        color: Theme.selection
        visible: root.lit
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 6
        spacing: 6

        BarText {
            visible: root.reserveCheck
            Layout.preferredWidth: 10
            horizontalAlignment: Text.AlignHCenter
            text: !root.checked ? "" : root.checkType === 2 ? "•" : "√"
            color: root.lit ? Theme.selectionText : Theme.text
        }

        IconImage {
            visible: root.icon !== ""
            source: root.icon
            implicitSize: 16
        }

        BarText {
            Layout.fillWidth: true
            text: root.text
            font.bold: root.bold
            color: root.lit ? Theme.selectionText : Theme.text
        }

        BarText {
            visible: root.hint !== ""
            text: root.hint
            color: root.lit ? Theme.selectionText : Theme.textDim
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}

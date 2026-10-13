import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

Item {
    id: root

    property bool active: false
    property bool flat: false
    property string icon: ""
    property string text: ""
    property int iconSize: 14
    property bool bold: false
    property string tooltip: ""

    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed
    readonly property bool sunken: pressed || active

    default property alias content: inner.data

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.barHeight
    opacity: enabled ? 1 : 0.5

    Bevel {
        anchors.fill: parent
        visible: !root.flat || root.hovered || root.sunken
        sunken: root.sunken
        faceColor: {
            if (root.active)
                return root.hovered ? Theme.activeFaceHover : Theme.activeFace
            if (root.pressed)
                return Theme.facePressed
            return root.hovered ? Theme.faceHover : Theme.face
        }
    }

    Item {
        id: inner

        anchors.fill: parent
        transform: Translate {
            x: root.sunken ? 1 : 0
            y: root.sunken ? 1 : 0
        }

        RowLayout {
            id: row

            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.ceil((parent.height - height) / 2)
            spacing: 4

            IconImage {
                visible: root.icon !== ""
                source: root.icon
                implicitSize: root.iconSize
            }

            BarText {
                visible: root.text !== ""
                text: root.text
                font.bold: root.bold
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }

    property bool tipVisible: false

    onHoveredChanged: {
        tipVisible = false
        if (hovered && tooltip !== "")
            tipDelay.restart()
        else
            tipDelay.stop()
    }
    onPressedChanged: {
        tipVisible = false
        tipDelay.stop()
    }

    Timer {
        id: tipDelay
        interval: 700
        onTriggered: root.tipVisible = true
    }

    LazyLoader {
        active: root.tipVisible && root.tooltip !== "" && Popups.current === null

        ToolTip {
            target: root
            text: root.tooltip
        }
    }
}

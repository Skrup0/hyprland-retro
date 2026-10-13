import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property real step: 0.05

    signal moved(real value)

    implicitWidth: 160
    implicitHeight: 16

    readonly property real clamped: Math.min(1, Math.max(0, value))

    Bevel {
        anchors.fill: parent
        sunken: true
        faceColor: Theme.field
    }

    Rectangle {
        x: 2
        y: 2
        height: parent.height - 4
        width: (parent.width - 4) * root.clamped
        color: Theme.selection
    }

    Bevel {
        width: 10
        height: parent.height
        x: (parent.width - width) * root.clamped
        faceColor: area.containsMouse || area.pressed ? Theme.faceHover : Theme.face
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true

        function setFromX(x) {
            root.moved(Math.min(1, Math.max(0, (x - 5) / (width - 10))))
        }

        onPressed: mouse => setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                setFromX(mouse.x)
        }
        onWheel: wheel => root.moved(Math.min(1, Math.max(0, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}

import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property int segments: 10
    property real warnAt: 0.7
    property real hotAt: 0.9
    property int segmentWidth: 3

    implicitWidth: segments * (segmentWidth + 1) - 1
    implicitHeight: 12

    Row {
        anchors.fill: parent
        spacing: 1

        Repeater {
            model: root.segments

            delegate: Rectangle {
                required property int index

                readonly property real level: (index + 1) / root.segments
                readonly property bool lit: root.value >= level - 0.5 / root.segments

                width: root.segmentWidth
                height: root.height
                color: !lit ? Theme.lcdOff
                     : level > root.hotAt ? Theme.lcdHot
                     : level > root.warnAt ? Theme.lcdWarn
                     : Theme.lcdOn
            }
        }
    }
}

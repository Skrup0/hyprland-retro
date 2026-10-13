import QtQuick
import qs.config

Item {
    id: root

    property real level: 0
    property bool charging: false

    implicitWidth: 20
    implicitHeight: 10

    Rectangle {
        width: parent.width - 2
        height: parent.height
        color: Theme.field
        border.width: 1
        border.color: Theme.text

        Rectangle {
            x: 2
            y: 2
            height: parent.height - 4
            width: Math.round((parent.width - 4) * Math.min(1, Math.max(0, root.level)))
            color: root.charging ? Theme.selection : root.level <= 0.15 ? Theme.warning : Theme.text
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 4
        color: Theme.text
    }
}

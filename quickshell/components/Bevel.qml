import QtQuick
import qs.config

Item {
    id: root

    property bool sunken: false
    property color faceColor: Theme.face

    Rectangle {
        anchors.fill: parent
        color: root.sunken ? Theme.bevelLight : Theme.bevelShadow
    }

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        color: root.sunken ? Theme.bevelShadow : Theme.bevelHighlight
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: root.sunken ? Theme.bevelHighlight : Theme.bevelDark
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.leftMargin: 1
        anchors.rightMargin: 2
        anchors.bottomMargin: 2
        color: root.sunken ? Theme.bevelDark : Theme.bevelLight
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: root.faceColor
    }
}

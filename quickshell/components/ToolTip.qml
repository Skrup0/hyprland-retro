import QtQuick
import Quickshell
import qs.config

PopupWindow {
    id: root

    required property Item target
    property string text

    readonly property bool above: target.QsWindow.window?.anchors.bottom === true
        && target.QsWindow.window?.anchors.top !== true

    anchor.item: target
    anchor.edges: above ? Edges.Top : Edges.Bottom
    anchor.gravity: above ? Edges.Top : Edges.Bottom
    visible: true
    color: "transparent"
    mask: Region {}

    implicitWidth: label.implicitWidth + 10
    implicitHeight: label.implicitHeight + 6 + 3

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.above ? 0 : 3
        anchors.bottomMargin: root.above ? 3 : 0
        color: Theme.window
        border.width: 1
        border.color: Theme.windowBorder

        BarText {
            id: label
            anchors.centerIn: parent
            text: root.text
            elide: Text.ElideNone
        }
    }
}

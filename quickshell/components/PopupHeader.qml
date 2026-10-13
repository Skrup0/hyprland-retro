import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string text

    Layout.fillWidth: true
    spacing: 4

    BarText {
        Layout.fillWidth: true
        text: root.text
        font.bold: true
    }
}

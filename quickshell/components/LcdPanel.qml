import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    property string label
    property string readout
    property string readoutSample: "100%"
    property color readoutColor: Theme.lcdOn

    default property alias content: picture.data

    implicitWidth: row.implicitWidth + 10
    implicitHeight: 20

    Bevel {
        anchors.fill: parent
        sunken: true
        faceColor: Theme.lcd
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        spacing: 5

        BarText {
            text: root.label
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.lcdOn
            opacity: 0.6
        }

        RowLayout {
            id: picture
            spacing: 2
        }

        BarText {
            Layout.preferredWidth: sample.advanceWidth
            horizontalAlignment: Text.AlignRight
            text: root.readout
            color: root.readoutColor
        }
    }

    TextMetrics {
        id: sample
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        text: root.readoutSample
    }
}

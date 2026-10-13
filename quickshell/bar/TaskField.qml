import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.popups
import qs.services

BarButton {
    id: root

    function toggle() {
        picker.toggle()
    }

    flat: true
    implicitWidth: 300
    active: picker.shown
    tooltip: Emacs.clocking ? "Clocked in: " + Emacs.task + "\nRight click: open in Emacs" : ""

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton && Study.lastTask)
            Emacs.open(Study.lastTask)
        else
            picker.toggle()
    }

    Item {
        anchors.fill: parent
        anchors.margins: 2

        Bevel {
            anchors.fill: parent
            sunken: true
            faceColor: Theme.field
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6

            BarText {
                text: "NOW"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
            }

            BarText {
                Layout.fillWidth: true
                text: Emacs.clocking ? Emacs.task : Study.lastTask ? Study.lastTask.heading : "Pick a task..."
                color: Emacs.clocking ? Theme.text : Theme.textMuted
            }
        }
    }

    TaskPicker {
        id: picker
        anchorItem: root
    }
}

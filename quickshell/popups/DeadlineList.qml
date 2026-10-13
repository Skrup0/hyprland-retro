import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarPopup {
    id: popup

    property real now: Date.now() / 1000

    align: Qt.AlignRight
    padding: 2
    spacing: 0

    onShownChanged: if (shown) now = Date.now() / 1000

    PopupHeader {
        Layout.leftMargin: 4
        text: "Deadlines"

        BarButton {
            implicitHeight: 20
            text: "Agenda"
            onClicked: {
                Emacs.agenda()
                popup.close()
            }
        }
    }

    Separator {
        vertical: false
    }

    Repeater {
        model: Org.deadlines.slice(0, 12)

        delegate: MenuRow {
            required property var modelData

            Layout.minimumWidth: 300
            Layout.maximumWidth: 460
            text: modelData.heading
            hint: Org.dueText(modelData, popup.now)
            onClicked: {
                Emacs.open(modelData)
                popup.close()
            }
        }
    }
}

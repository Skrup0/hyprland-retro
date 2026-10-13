import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

BarPopup {
    id: popup

    align: Qt.AlignLeft
    padding: 4
    implicitWidth: 220
    onShownChanged: if (shown) Theme.refreshThemes()

    PopupHeader {
        text: "Theme"

        BarButton {
            implicitWidth: 44
            implicitHeight: 20
            text: "Light"
            active: !Theme.dark
            onClicked: Theme.setDark(false)
        }

        BarButton {
            implicitWidth: 44
            implicitHeight: 20
            text: "Dark"
            active: Theme.dark
            onClicked: Theme.setDark(true)
        }
    }

    Separator {
        vertical: false
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: Theme.themes

            delegate: MenuRow {
                required property var modelData

                text: modelData.name
                checkType: 2
                checked: modelData.id === Theme.current
                onClicked: Theme.setTheme(modelData.id)
            }
        }
    }
}

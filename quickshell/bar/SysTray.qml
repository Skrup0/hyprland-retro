import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.components
import qs.config

Item {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: row.implicitWidth + 6

    Bevel {
        anchors.fill: parent
        sunken: true
        faceColor: Theme.bar
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 1

        Repeater {
            model: SystemTray.items

            delegate: TrayItem {}
        }
    }
}

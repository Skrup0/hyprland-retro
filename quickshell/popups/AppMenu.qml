import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

BarPopup {
    id: popup

    property var entry
    property var trayItem
    property string appName
    property var appWindows: []

    readonly property var actions: entry ? [...entry.actions] : []
    readonly property bool ownNewWindow: actions.some(a => /new.*window/i.test(a.name))

    function newWindow() {
        if (entry.runInTerminal)
            Quickshell.execDetached([Theme.terminal, "-e", ...entry.command])
        else
            entry.execute()
        close()
    }

    align: Qt.AlignLeft
    padding: 2
    spacing: 0

    ColumnLayout {
        Layout.fillWidth: true
        visible: !tray.inSubmenu
        spacing: 0

        MenuRow {
            visible: popup.entry !== null && !popup.ownNewWindow
            text: "New Window"
            reserveCheck: tray.anyChecks
            onClicked: popup.newWindow()
        }

        Repeater {
            model: popup.actions

            delegate: MenuRow {
                required property var modelData

                text: modelData.name
                reserveCheck: tray.anyChecks
                icon: modelData.icon !== "" ? Quickshell.iconPath(modelData.icon, true) : ""
                onClicked: {
                    modelData.execute()
                    popup.close()
                }
            }
        }

        Separator {
            visible: popup.entry !== null && popup.trayItem !== null
            vertical: false
        }
    }

    MenuEntries {
        id: tray

        visible: popup.trayItem !== null
        handle: popup.trayItem?.menu ?? null
        open: popup.shown && popup.trayItem !== null
        onTriggered: popup.close()
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !tray.inSubmenu
        spacing: 0

        Separator {
            visible: popup.entry !== null || popup.trayItem !== null
            vertical: false
        }

        MenuRow {
            Layout.minimumWidth: 180
            text: "Quit " + popup.appName
            reserveCheck: tray.anyChecks
            hint: popup.appWindows.length > 1 ? popup.appWindows.length + " windows" : ""
            onClicked: {
                popup.appWindows.forEach(w => Windows.close(w))
                popup.close()
            }
        }
    }
}

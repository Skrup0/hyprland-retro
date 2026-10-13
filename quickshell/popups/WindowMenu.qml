import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services

BarPopup {
    id: popup

    property var toplevel
    property string appName
    property var appWindows: []

    readonly property var ipc: toplevel?.lastIpcObject ?? ({})
    readonly property bool floating: ipc.floating ?? false
    readonly property bool pinned: ipc.pinned ?? false
    readonly property int fullscreen: ipc.fullscreen ?? 0
    readonly property int workspaceId: toplevel?.workspace?.id ?? 0

    function act(name, ...args) {
        Windows[name](toplevel, ...args)
        close()
    }

    onShownChanged: if (shown) Hyprland.refreshToplevels()

    align: Qt.AlignLeft
    padding: 2
    spacing: 0

    MenuRow {
        Layout.minimumWidth: 180
        text: "Floating"
        checkType: 1
        checked: popup.floating
        onClicked: popup.act("toggleFloating")
    }

    MenuRow {
        text: "On All Workspaces"
        hint: popup.floating ? "" : "floating only"
        checkType: 1
        checked: popup.pinned
        enabled: popup.floating
        onClicked: popup.act("togglePin")
    }

    MenuRow {
        text: "Maximize"
        checkType: 1
        checked: popup.fullscreen === 1
        onClicked: popup.act("toggleFullscreen", "maximized")
    }

    MenuRow {
        text: "Fullscreen"
        checkType: 1
        checked: popup.fullscreen === 2
        onClicked: popup.act("toggleFullscreen", "fullscreen")
    }

    Separator {
        vertical: false
    }

    BarText {
        Layout.leftMargin: 20
        Layout.topMargin: 2
        text: "Move to workspace"
        color: Theme.textDim
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 6
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        columns: 5
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: 10

            delegate: BarButton {
                required property int index

                readonly property int workspace: index + 1

                Layout.fillWidth: true
                implicitWidth: 26
                implicitHeight: 20
                text: workspace
                active: workspace === popup.workspaceId
                onClicked: {
                    if (active)
                        popup.close()
                    else
                        popup.act("moveToWorkspace", workspace)
                }
            }
        }
    }

    Separator {
        visible: popup.appWindows.length > 1
        vertical: false
    }

    Repeater {
        model: popup.appWindows.length > 1 ? popup.appWindows : []

        delegate: MenuRow {
            required property var modelData

            Layout.maximumWidth: 320
            text: modelData.title || popup.appName
            hint: modelData.workspace?.name ?? ""
            checkType: 2
            checked: modelData === popup.toplevel
            onClicked: {
                Windows.focus(modelData)
                popup.close()
            }
        }
    }

    Separator {
        vertical: false
    }

    MenuRow {
        text: "Close Window"
        hint: "Mid-click"
        reserveCheck: true
        onClicked: popup.act("close")
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config
import qs.popups
import qs.services

RowLayout {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool focusedScreen: Hyprland.focusedMonitor === monitor

    readonly property HyprlandToplevel activeHere: Windows.focused?.monitor === monitor ? Windows.focused : null
    property HyprlandToplevel lastFocused: null
    onActiveHereChanged: if (activeHere) lastFocused = activeHere

    readonly property HyprlandToplevel candidate: {
        if (activeHere) return activeHere
        const workspace = monitor?.activeWorkspace
        if (lastFocused && lastFocused.workspace === workspace) return lastFocused
        return workspace?.toplevels.values[0] ?? null
    }

    property HyprlandToplevel toplevel: null
    readonly property bool menuOpen: appMenu.shown || windowMenu.shown

    function sync() {
        if (!menuOpen)
            toplevel = candidate
    }

    onCandidateChanged: sync()
    onMenuOpenChanged: sync()
    Component.onCompleted: sync()

    readonly property string appId: toplevel?.wayland?.appId ?? toplevel?.lastIpcObject?.class ?? ""
    readonly property var entry: {
        DesktopEntries.applications.values
        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    }
    readonly property string appName: entry?.name || appId
    readonly property var appWindows: [...Hyprland.toplevels.values]
        .filter(t => (t.wayland?.appId ?? t.lastIpcObject?.class) === appId)

    readonly property var trayItem: {
        if (!toplevel) return null
        const norm = s => (s ?? "").toLowerCase().replace(/[^a-z0-9]/g, "")
        const names = [appId, entry?.id, entry?.name, entry?.startupClass].map(norm).filter(s => s.length > 1)
        return SystemTray.items.values.find(i => i.hasMenu && (names.includes(norm(i.id)) || names.includes(norm(i.title)))) ?? null
    }

    function cycle(step) {
        const windows = [...(monitor?.activeWorkspace?.toplevels.values ?? [])]
        if (windows.length < 2) return
        const current = windows.indexOf(toplevel)
        Windows.focus(windows[(current + step + windows.length) % windows.length])
    }

    spacing: 0

    BarText {
        Layout.leftMargin: 8
        visible: root.toplevel === null
        text: "Desktop"
        font.bold: true
        color: Theme.textMuted
    }

    BarButton {
        id: appButton

        Layout.fillHeight: true
        Layout.maximumWidth: 240
        visible: root.toplevel !== null
        flat: true
        implicitWidth: appRow.implicitWidth + 16
        active: appMenu.shown
        tooltip: "Right click: window menu"

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Windows.close(root.toplevel)
            else if (mouse.button === Qt.RightButton)
                windowMenu.toggle()
            else
                appMenu.toggle()
        }
        onScrolled: wheel => root.cycle(wheel.angleDelta.y > 0 ? -1 : 1)

        RowLayout {
            id: appRow

            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            IconImage {
                implicitSize: 14
                source: Quickshell.iconPath(root.entry?.icon ?? root.appId, "application-x-executable")
            }

            BarText {
                Layout.fillWidth: true
                text: root.appName
                font.bold: true
                color: root.focusedScreen ? Theme.text : Theme.textDim
            }
        }

        AppMenu {
            id: appMenu

            anchorItem: appButton
            entry: root.entry
            trayItem: root.trayItem
            appName: root.appName
            appWindows: root.appWindows
        }
    }

    BarButton {
        id: windowButton

        Layout.fillHeight: true
        visible: root.toplevel !== null
        flat: true
        text: "Window"
        active: windowMenu.shown
        onClicked: windowMenu.toggle()
        onScrolled: wheel => root.cycle(wheel.angleDelta.y > 0 ? -1 : 1)

        WindowMenu {
            id: windowMenu

            anchorItem: windowButton
            toplevel: root.toplevel
            appName: root.appName
            appWindows: root.appWindows
        }
    }

    BarText {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        visible: root.toplevel !== null
        text: root.toplevel?.title ?? ""
        color: root.focusedScreen ? Theme.textDim : Theme.textMuted
    }

    Item {
        Layout.fillWidth: true
        visible: root.toplevel === null
    }
}

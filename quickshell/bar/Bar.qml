import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config

PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: implicitHeight
    color: Theme.bar
    WlrLayershell.namespace: "retrobar"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        StartButton {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Workspaces {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Separator {}

        FocusedApp {
            screen: bar.screen
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Separator {}

        SysTray {
            Layout.fillHeight: true
        }

        SysMonitor {
            Layout.fillHeight: true
            Layout.leftMargin: 2
        }

        VolumeButton {
            Layout.fillHeight: true
        }

        BatteryButton {
            Layout.fillHeight: true
        }

        NotifButton {
            Layout.fillHeight: true
        }

        Clock {
            Layout.fillHeight: true
        }
    }
}

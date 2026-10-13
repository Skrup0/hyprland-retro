import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: implicitHeight
    color: Theme.bar
    WlrLayershell.namespace: "retrobar-study"

    RowLayout {
        anchors.fill: parent
        spacing: 2

        PomodoroDeck {
            Layout.fillHeight: true
            onPickTask: task.toggle()
        }

        TaskField {
            id: task
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 140
            Layout.maximumWidth: 300
        }

        Item {
            Layout.fillWidth: true
        }

        DeadlinePanel {
            Layout.fillHeight: true
        }

        FlashcardPanel {
            Layout.fillHeight: true
        }

        ProgressPanel {
            Layout.fillHeight: true
        }

        Separator {}

        MusicDeck {
            Layout.fillHeight: true
        }

        Separator {}

        BarButton {
            Layout.fillHeight: true
            text: "+ Note"
            tooltip: "org-capture in Emacs"
            onClicked: Emacs.capture()
        }
    }
}

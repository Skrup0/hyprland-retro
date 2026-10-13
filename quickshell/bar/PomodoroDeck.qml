import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root

    signal pickTask()

    readonly property string label: !Emacs.up ? "EMACS"
        : Emacs.phase === "pomodoro" ? "POMO"
        : Emacs.phase === "short-break" ? "BREAK"
        : Emacs.phase === "long-break" ? "REST"
        : Emacs.phase === "overtime" ? "OVER" : "IDLE"

    function clock(seconds) {
        return `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`
    }

    spacing: 0

    BarButton {
        Layout.fillHeight: true
        implicitWidth: 26
        active: Emacs.phase === "pomodoro"
        tooltip: Emacs.running ? "" : Study.lastTask ? "Start a pomodoro: " + Study.lastTask.heading : "Pick a task to start"
        onClicked: {
            if (Emacs.running) return
            if (Study.lastTask)
                Emacs.start(Study.lastTask)
            else
                root.pickTask()
        }

        DeckIcon {
            anchors.centerIn: parent
            kind: "play"
        }
    }

    BarButton {
        Layout.fillHeight: true
        implicitWidth: 26
        enabled: Emacs.running || Emacs.clocking
        tooltip: Emacs.onBreak ? "End the break" : "Stop"
        onClicked: Emacs.stop()

        DeckIcon {
            anchors.centerIn: parent
            kind: "stop"
        }
    }

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: lcd.implicitWidth + 4
        tooltip: !Emacs.up ? "Emacs isn't running; Play starts it"
            : `${Emacs.count} pomodoro${Emacs.count === 1 ? "" : "s"} since the last long break`
        onClicked: root.pickTask()

        LcdPanel {
            id: lcd

            anchors.centerIn: parent
            label: root.label
            readout: !Emacs.up ? "OFF" : Emacs.running ? root.clock(Emacs.remaining) : "--:--"
            readoutSample: "88:88"
            readoutColor: !Emacs.up ? Theme.lcdHot : Emacs.onBreak ? Theme.lcdWarn : Theme.lcdOn

            Row {
                spacing: 2

                Repeater {
                    model: Emacs.frequency

                    delegate: Rectangle {
                        required property int index

                        readonly property int done: Emacs.count % Emacs.frequency === 0 && Emacs.count > 0 && Emacs.onBreak
                            ? Emacs.frequency : Emacs.count % Emacs.frequency

                        width: 4
                        height: 4
                        color: index < done ? Theme.lcdOn : Theme.lcdOff
                    }
                }
            }
        }
    }
}

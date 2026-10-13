import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root

    spacing: 2

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: today.implicitWidth + 4
        tooltip: `Clocked today: ${Study.hm(Study.todayMinutes)} of a ${Study.hm(Study.goal)} goal`
            + (Study.todayMinutes >= Study.goal ? " (made it!)" : "")

        LcdPanel {
            id: today

            anchors.centerIn: parent
            label: "TODAY"
            readout: Study.hm(Study.todayMinutes)
            readoutSample: "88h88"

            LedMeter {
                value: Study.todayMinutes / Study.goal
                warnAt: 2
                hotAt: 2
            }
        }
    }

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: streak.implicitWidth + 4
        tooltip: `${Study.streak} day${Study.streak === 1 ? "" : "s"} in a row at ${Study.hm(Study.goal)} or more`

        LcdPanel {
            id: streak

            anchors.centerIn: parent
            label: "STREAK"
            readout: Study.streak + "d"
            readoutSample: "888d"
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.popups
import qs.services

BarButton {
    id: root

    readonly property var task: Org.deadlines[0] ?? null
    readonly property real secondsLeft: task ? Org.secondsLeft(task, clock.date.getTime() / 1000) : 0

    visible: task !== null
    flat: true
    implicitWidth: lcd.implicitWidth + 4
    active: list.shown
    tooltip: task ? `${task.heading}\n${task.category} · due ${Qt.formatDateTime(new Date(task.deadline * 1000), task.deadlineAllDay ? "ddd d MMM" : "ddd d MMM h:mm AP")}` : ""
    onClicked: list.toggle()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    LcdPanel {
        id: lcd

        anchors.centerIn: parent
        label: "DUE"
        readout: root.task ? Org.dueText(root.task, clock.date.getTime() / 1000) : ""
        readoutSample: "88d 88h"
        readoutColor: root.secondsLeft < 86400 ? Theme.lcdHot : root.secondsLeft < 3 * 86400 ? Theme.lcdWarn : Theme.lcdOn

        BarText {
            Layout.maximumWidth: 220
            text: root.task?.heading ?? ""
            color: Theme.lcdOn
        }
    }

    DeadlineList {
        id: list
        anchorItem: root
    }
}

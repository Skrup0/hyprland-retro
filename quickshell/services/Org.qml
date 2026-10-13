pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var tasks: []
    property var clocked: ({})

    property var cards: ({ total: 0, review: 0 })

    readonly property var deadlines: tasks.filter(t => t.deadline !== null).sort((a, b) => a.deadline - b.deadline)

    function rescan() {
        if (scan.running)
            scanAgain = true
        else
            scan.running = true
    }

    property bool scanAgain: false

    function dueText(task, now) {
        const due = new Date(task.deadline * 1000)
        if (task.deadlineAllDay) {
            const today = new Date(now * 1000)
            today.setHours(0, 0, 0, 0)
            const days = Math.round((due - today) / 86400000)
            return days < 0 ? `${-days}d LATE` : days === 0 ? "TODAY" : days === 1 ? "TOMORROW" : `${days}d`
        }
        const minutes = Math.round((task.deadline - now) / 60)
        if (minutes < 0) {
            const late = -minutes
            return late < 60 ? `${late}m LATE` : late < 1440 ? `${Math.floor(late / 60)}h LATE` : `${Math.floor(late / 1440)}d LATE`
        }
        if (minutes < 60) return `${minutes}m`
        if (minutes < 1440) return `${Math.floor(minutes / 60)}h ${minutes % 60}m`
        return `${Math.floor(minutes / 1440)}d ${Math.floor(minutes % 1440 / 60)}h`
    }

    function secondsLeft(task, now) {
        return task.deadline + (task.deadlineAllDay ? 86400 : 0) - now
    }

    Process {
        id: scan

        running: true
        command: ["bash", Quickshell.shellPath("scripts/org-scan.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    root.tasks = result.tasks
                    root.clocked = result.clocked
                    root.cards = result.cards
                } catch (e) {
                    console.warn("study: org scan failed:", e)
                }
            }
        }

        onExited: {
            if (root.scanAgain) {
                root.scanAgain = false
                running = true
            }
        }
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property var lastTask: Emacs.clocking && Emacs.file !== ""
        ? { file: Emacs.file, heading: Emacs.task }
        : saved.lastHeading !== "" ? { file: saved.lastFile, heading: saved.lastHeading } : null

    function remember() {
        if (Emacs.clocking && !Emacs.reviewClock && Emacs.task !== "" && Emacs.file !== "") {
            saved.lastFile = Emacs.file
            saved.lastHeading = Emacs.task
        }
    }

    function pick(task) {
        saved.lastFile = task.file
        saved.lastHeading = task.heading
        Emacs.start(task)
    }

    function dayKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    readonly property string today: dayKey(clock.date)
    readonly property real runningMinutes: Emacs.clocking && Emacs.clockStart > 0
        ? Math.max(0, (Emacs.now - Emacs.clockStart) / 60) : 0
    readonly property int todayMinutes: Math.round((Org.clocked[today] ?? 0) + runningMinutes)
    readonly property int goal: Theme.studyGoalMinutes

    readonly property int streak: {
        let days = todayMinutes >= goal ? 1 : 0
        const day = new Date(clock.date)
        day.setDate(day.getDate() - 1)
        while ((Org.clocked[dayKey(day)] ?? 0) >= goal) {
            days++
            day.setDate(day.getDate() - 1)
        }
        return days
    }

    function hm(minutes) {
        return `${Math.floor(minutes / 60)}h${String(minutes % 60).padStart(2, "0")}`
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: Org.rescan()
    }

    Timer {
        id: rescanSoon
        interval: 1500
        onTriggered: Org.rescan()
    }

    Connections {
        target: Emacs

        function onClockingChanged() {
            rescanSoon.restart()
            root.remember()
        }

        function onTaskChanged() {
            root.remember()
        }

        function onCardsUpdated() {
            rescanSoon.restart()
        }

        function onPhaseChanged() {
            root.handlePhase(Emacs.phase)
        }
    }

    property string lastPhase: "none"
    property real lastEnd: 0
    property bool dndByUs: false

    function handlePhase(phase) {
        const previous = lastPhase
        const ranOut = Date.now() / 1000 >= lastEnd - 5
        lastPhase = phase
        lastEnd = Emacs.end

        if (phase === "pomodoro" && !Notifs.dnd) {
            Notifs.dnd = true
            dndByUs = true
        } else if (phase !== "pomodoro" && dndByUs) {
            Notifs.dnd = false
            dndByUs = false
        }

        const breakMinutes = Math.round(Emacs.remaining / 60)
        if (previous === "pomodoro" && Emacs.onBreak)
            notify("Pomodoro done", `Take a ${breakMinutes} minute ${phase === "long-break" ? "long " : ""}break.`)
        else if ((previous === "short-break" || previous === "long-break") && phase === "none" && ranOut)
            notify("Break's over", "Back to it.")
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Study", title, body])
    }

    FileView {
        path: Quickshell.statePath("study.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: saved

            property string lastFile: ""
            property string lastHeading: ""
        }
    }
}

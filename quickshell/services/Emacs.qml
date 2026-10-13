pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string bridge: Quickshell.shellPath("emacs/studybar.el")

    property bool up: false
    property int seq: 0

    property string phase: "none"
    property real end: 0
    property int count: 0
    property int frequency: 4
    property bool clocking: false
    property string task: ""
    property real clockStart: 0
    property string file: ""
    property bool reviewClock: false

    signal cardsUpdated()

    readonly property bool running: phase !== "none"
    readonly property bool onBreak: phase === "short-break" || phase === "long-break"

    property real now: Date.now() / 1000
    readonly property int remaining: running ? Math.max(0, Math.round(end - now)) : 0

    Timer {
        running: root.running || root.clocking
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: root.now = Date.now() / 1000
    }

    function receive(json) {
        let s
        try {
            s = JSON.parse(json)
        } catch (e) {
            console.warn("study: bad update from Emacs:", e)
            return
        }
        if (s.event === "bye") {
            up = false
            phase = "none"
            clocking = false
            reviewClock = false
            task = ""
            return
        }
        if (s.event === "hello")
            seq = 0
        if (s.seq < seq)
            return
        seq = s.seq
        up = true
        now = Date.now() / 1000
        end = s.end
        count = s.count
        frequency = s.frequency
        reviewClock = s.reviewClock === true
        file = s.file
        task = s.task
        clockStart = s.clockStart
        clocking = s.clocking
        phase = s.state
        flush()
        if (s.event === "cards")
            cardsUpdated()
    }

    function lisp(s) {
        return JSON.stringify(String(s))
    }

    function start(task) {
        send(`(studybar-${running ? "switch" : "start"} ${lisp(task.file)} ${lisp(task.heading)})`)
    }

    function resume() {
        send("(studybar-resume)")
    }

    function stop() {
        send("(studybar-stop)")
    }

    function open(task) {
        send(`(studybar-open ${lisp(task.file)} ${lisp(task.heading)})`)
        focusEmacs()
    }

    function agenda() {
        send("(studybar-agenda)")
        focusEmacs()
    }

    function capture() {
        send("(studybar-capture)")
    }

    function review() {
        send("(studybar-review)")
        focusEmacs()
    }

    function isEmacs(toplevel) {
        return (toplevel.wayland?.appId ?? toplevel.lastIpcObject?.class ?? "").toLowerCase() === "emacs"
    }

    function focusEmacs() {
        const emacs = [...Hyprland.toplevels.values].find(t => isEmacs(t) && t.title !== "studybar-capture")
        if (emacs)
            Windows.focus(emacs)
    }

    readonly property var captureFrame: [...Hyprland.toplevels.values].find(t => t.title === "studybar-capture" && t.wayland) ?? null
    onCaptureFrameChanged: {
        if (captureFrame) {
            floatCaptureFrame()
            captureSettle.restart()
        }
    }

    function floatCaptureFrame() {
        Windows.floatCentered(captureFrame, 900, 420)
    }

    Timer {
        id: captureSettle
        interval: 300
        onTriggered: if (root.captureFrame) root.floatCaptureFrame()
    }

    property var queue: []
    property var waiting: []

    readonly property string askHello: `(when (featurep 'studybar) (studybar-push "hello"))`
    readonly property string loadBridge: `(progn (unless (featurep 'studybar) (load ${lisp(bridge)})) (studybar-push "hello"))`

    function send(elisp) {
        if (up)
            queue = [...queue, elisp]
        else {
            waiting = [...waiting, elisp]
            queue = [...queue, loadBridge]
        }
        next()
    }

    function flush() {
        if (waiting.length === 0) return
        queue = [...queue, ...waiting]
        waiting = []
        next()
    }

    function next() {
        if (client.running || queue.length === 0) return
        client.elisp = queue[0]
        client.command = ["emacsclient", "-e", client.elisp]
        queue = queue.slice(1)
        client.running = true
    }

    Process {
        id: client

        property string elisp

        stderr: StdioCollector {
            id: clientErrors
        }

        onExited: code => {
            if (code !== 0) {
                if (!root.up || /can't find socket|can't connect/.test(clientErrors.text)) {
                    root.up = false
                    if (client.elisp !== root.askHello && client.elisp !== root.loadBridge)
                        root.waiting = [client.elisp, ...root.waiting]
                    if (root.waiting.length > 0 && !launcher.running)
                        launcher.running = true
                } else {
                    console.warn("study: emacsclient:", clientErrors.text.trim())
                }
            }
            root.next()
        }
    }

    Process {
        id: launcher

        command: ["pgrep", "-x", "emacs"]
        onExited: code => {
            if (code !== 1 || root.waiting.length === 0)
                return
            const notesOnly = root.waiting.every(elisp => elisp === "(studybar-capture)")
            Quickshell.execDetached(notesOnly ? ["emacs", "-T", "studybar-capture"] : ["emacs"])
        }
    }

    Timer {
        running: root.waiting.length > 0
        interval: 60000
        onTriggered: root.waiting = []
    }

    Component.onCompleted: {
        queue = [askHello]
        next()
    }
}

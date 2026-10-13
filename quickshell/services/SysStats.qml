pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property int historyLength: 20

    property real cpu: 0
    property var cpuHistory: []
    property int threads: 0
    property string load: ""

    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0

    property real temp: NaN
    property string tempName: ""
    property string tempPath: Theme.tempSensor

    property var lastCpu: null

    function parseStat(text) {
        const lines = text.split("\n")
        const fields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number)
        const idle = fields[3] + fields[4]
        const total = fields.reduce((a, b) => a + b, 0)
        if (lastCpu && total > lastCpu.total) {
            cpu = Math.min(1, Math.max(0, 1 - (idle - lastCpu.idle) / (total - lastCpu.total)))
            cpuHistory = [...cpuHistory, cpu].slice(-historyLength)
        }
        lastCpu = { idle, total }
        threads = lines.filter(l => /^cpu\d/.test(l)).length
    }

    function parseMeminfo(text) {
        const kib = key => Number(text.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))?.[1] ?? 0)
        memTotal = kib("MemTotal")
        memUsed = memTotal - kib("MemAvailable")
        swapTotal = kib("SwapTotal")
        swapUsed = swapTotal - kib("SwapFree")
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            stat.reload()
            meminfo.reload()
            loadavg.reload()
            if (root.tempPath !== "")
                tempFile.reload()
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.parseMeminfo(text())
    }

    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).join(" ")
    }

    FileView {
        id: tempFile
        path: root.tempPath
        printErrors: false
        onLoaded: root.temp = Number(text().trim()) / 1000
        onLoadFailed: root.temp = NaN
    }

    Process {
        running: Theme.tempSensor === ""
        command: ["sh", "-c", `
            for want in k10temp zenpower coretemp cpu_thermal k8temp acpitz; do
                for h in /sys/class/hwmon/hwmon*; do
                    [ "$(cat "$h/name" 2>/dev/null)" = "$want" ] || continue
                    for f in "$h"/temp*_input; do
                        label=$(cat "\${f%_input}_label" 2>/dev/null)
                        case "$label" in Tctl|Tdie|"Package id 0")
                            printf '%s\\t%s %s\\n' "$f" "$want" "$label"; exit ;;
                        esac
                    done
                    [ -r "$h/temp1_input" ] && printf '%s\\t%s\\n' "$h/temp1_input" "$want" && exit
                done
            done
            z=/sys/class/thermal/thermal_zone0
            [ -r "$z/temp" ] && printf '%s\\t%s\\n' "$z/temp" "$(cat "$z/type")"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const [path, name] = text.trim().split("\t")
                root.tempPath = path ?? ""
                root.tempName = name ?? ""
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root

    function gib(kib) {
        return (kib / 1048576).toFixed(1)
    }

    function run(command) {
        Quickshell.execDetached([Theme.terminal, "-e", "sh", "-c", command])
    }

    spacing: 2

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: cpuPanel.implicitWidth + 4
        tooltip: `CPU ${Math.round(SysStats.cpu * 100)}% of ${SysStats.threads} threads\nLoad ${SysStats.load}`
        onClicked: root.run(Theme.taskManager)

        LcdPanel {
            id: cpuPanel

            anchors.centerIn: parent
            label: "CPU"
            readout: Math.round(SysStats.cpu * 100) + "%"
            readoutColor: SysStats.cpu >= 0.9 ? Theme.lcdHot : SysStats.cpu >= 0.7 ? Theme.lcdWarn : Theme.lcdOn

            HistoryGraph {
                implicitWidth: SysStats.historyLength * step
                values: SysStats.cpuHistory
            }
        }
    }

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: memPanel.implicitWidth + 4
        tooltip: `Memory ${root.gib(SysStats.memUsed)} of ${root.gib(SysStats.memTotal)} GiB used (${Math.round(SysStats.mem * 100)}%)`
            + (SysStats.swapTotal > 0 ? `\nSwap ${root.gib(SysStats.swapUsed)} of ${root.gib(SysStats.swapTotal)} GiB` : "")
        onClicked: root.run(Theme.taskManager)

        LcdPanel {
            id: memPanel

            anchors.centerIn: parent
            label: "MEM"
            readout: root.gib(SysStats.memUsed) + "G"
            readoutSample: "88.8G"
            readoutColor: SysStats.mem >= 0.9 ? Theme.lcdHot : SysStats.mem >= 0.7 ? Theme.lcdWarn : Theme.lcdOn

            LedMeter {
                value: SysStats.mem
            }
        }
    }

    BarButton {
        Layout.fillHeight: true
        visible: !isNaN(SysStats.temp)
        flat: true
        implicitWidth: tempPanel.implicitWidth + 4
        tooltip: `${SysStats.tempName || "CPU"}: ${SysStats.temp.toFixed(1)} °C`
        onClicked: root.run(Theme.taskManager)

        LcdPanel {
            id: tempPanel

            anchors.centerIn: parent
            label: "TMP"
            readout: Math.round(SysStats.temp) + "°C"
            readoutSample: "100°C"
            readoutColor: SysStats.temp >= 85 ? Theme.lcdHot : SysStats.temp >= 70 ? Theme.lcdWarn : Theme.lcdOn

            LedMeter {
                segments: 8
                value: (SysStats.temp - 30) / 70
                warnAt: (70 - 30) / 70
                hotAt: (85 - 30) / 70
            }
        }
    }
}

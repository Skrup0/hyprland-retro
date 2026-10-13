import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.components
import qs.config

RowLayout {
    id: root

    readonly property var player: [...Mpris.players.values].find(p => p.isPlaying)
        ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string track: !player ? ""
        : [player.trackArtist, player.trackTitle || player.identity].filter(s => s).join(" - ")
    readonly property bool idle: !player || track === "" || player.playbackState === MprisPlaybackState.Stopped
    readonly property string display: idle ? "Nothing playing" : track

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
    }

    spacing: 0

    Timer {
        running: root.playing
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }

    BarButton {
        Layout.fillHeight: true
        implicitWidth: 26
        enabled: root.player?.canGoPrevious ?? false
        onClicked: root.player.previous()

        DeckIcon {
            anchors.centerIn: parent
            kind: "previous"
        }
    }

    BarButton {
        Layout.fillHeight: true
        implicitWidth: 26
        active: root.playing
        enabled: root.player?.canTogglePlaying ?? false
        onClicked: root.player.togglePlaying()

        DeckIcon {
            anchors.centerIn: parent
            kind: root.playing ? "pause" : "play"
        }
    }

    BarButton {
        Layout.fillHeight: true
        implicitWidth: 26
        enabled: root.player?.canGoNext ?? false
        onClicked: root.player.next()

        DeckIcon {
            anchors.centerIn: parent
            kind: "next"
        }
    }

    BarButton {
        Layout.fillHeight: true
        flat: true
        implicitWidth: lcd.implicitWidth + 4
        tooltip: !root.player ? "" : [
            root.player.trackTitle, root.player.trackArtist, root.player.trackAlbum,
            root.player.identity + (root.player.canRaise ? " (click to show)" : "")
        ].filter(s => s).join("\n")
        onClicked: if (root.player?.canRaise) root.player.raise()

        LcdPanel {
            id: lcd

            anchors.centerIn: parent
            label: root.playing ? "PLAY" : root.idle ? "STOP" : "PAUSE"
            readout: !root.idle && root.player.positionSupported ? root.time(root.player.position) : "--:--"
            readoutSample: "88:88"

            Item {
                id: marquee

                readonly property bool overflows: measure.advanceWidth > width
                readonly property string loop: root.display + "    "
                property int step: 0

                implicitWidth: 170
                implicitHeight: shown.implicitHeight
                clip: true

                BarText {
                    id: shown
                    text: marquee.overflows ? marquee.loop.slice(marquee.step) + marquee.loop.slice(0, marquee.step) : root.display
                    color: Theme.lcdOn
                    opacity: root.idle ? 0.6 : 1
                    elide: Text.ElideNone
                }

                TextMetrics {
                    id: measure
                    font: shown.font
                    text: root.display
                }

                Connections {
                    target: root

                    function onDisplayChanged() {
                        marquee.step = 0
                    }
                }

                Timer {
                    running: marquee.overflows && root.playing
                    repeat: true
                    interval: 350
                    onTriggered: marquee.step = (marquee.step + 1) % marquee.loop.length
                }
            }
        }
    }
}

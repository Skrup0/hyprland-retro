pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string defaultTheme: "vesper"
    readonly property bool defaultDark: true

    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 11
    readonly property int barHeight: 24

    readonly property string startIcon: "file://" + Quickshell.shellPath("assets/gentoo-logo.svg")
    readonly property string startLabel: "Gentoo"
    readonly property string terminal: "foot"

    readonly property string taskManager: "btop"
    readonly property string tempSensor: ""

    readonly property int studyGoalMinutes: 240

    readonly property string current: saved.theme
    readonly property bool dark: saved.dark
    readonly property string name: themeFile.parsed?.name ?? current
    property var themes: []

    function setTheme(id: string) {
        saved.theme = id
    }

    function setDark(value: bool) {
        saved.dark = value
    }

    function refreshThemes() {
        themeScan.running = true
    }

    readonly property color bevelHighlight: pick("bevelHighlight")
    readonly property color bevelLight: pick("bevelLight")
    readonly property color bevelDark: pick("bevelDark")
    readonly property color bevelShadow: pick("bevelShadow")

    readonly property color bar: pick("bar")
    readonly property color face: pick("face")
    readonly property color faceHover: pick("faceHover")
    readonly property color facePressed: pick("facePressed")
    readonly property color activeFace: pick("activeFace")
    readonly property color activeFaceHover: pick("activeFaceHover")

    readonly property color window: pick("window")
    readonly property color windowBorder: pick("windowBorder")
    readonly property color field: pick("field")

    readonly property color text: pick("text")
    readonly property color textDim: pick("textDim")
    readonly property color textMuted: pick("textMuted")

    readonly property color selection: pick("selection")
    readonly property color selectionText: pick("selectionText")
    readonly property color titleInactive: pick("titleInactive")
    readonly property color titleInactiveText: pick("titleInactiveText")
    readonly property color warning: pick("warning")

    readonly property color lcd: pick("lcd")
    readonly property color lcdOn: pick("lcdOn")
    readonly property color lcdOff: pick("lcdOff")
    readonly property color lcdGrid: pick("lcdGrid")
    readonly property color lcdWarn: pick("lcdWarn")
    readonly property color lcdHot: pick("lcdHot")

    readonly property string font: {
        const wanted = themeFile.parsed?.font ?? ""
        return wanted !== "" && Qt.fontFamilies().includes(wanted) ? wanted : "Terminus"
    }

    readonly property var palette: themeFile.parsed?.[dark ? "dark" : "light"] ?? {}

    function pick(key) {
        return palette[key]
    }

    readonly property string themeDir: Quickshell.shellPath("config/themes")

    FileView {
        id: themeFile

        property var parsed: null

        path: `${root.themeDir}/${root.current}.json`
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                parsed = JSON.parse(text())
            } catch (e) {
                console.warn(`Theme ${path}: ${e}`)
            }
        }
        onLoadFailed: root.setTheme(root.defaultTheme)
    }

    FileView {
        path: Quickshell.statePath("theme.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: saved

            property string theme: root.defaultTheme
            property bool dark: root.defaultDark
        }
    }

    Process {
        id: themeScan

        running: true
        command: ["sh", "-c", 'cd "$1" && grep -H -m1 \'"name"\' -- *.json', "sh", root.themeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.themes = text.split("\n").filter(line => line !== "").map(line => {
                    const id = line.slice(0, line.indexOf(".json:"))
                    const name = line.match(/"name"\s*:\s*"([^"]*)"/)?.[1] ?? id
                    return { id, name }
                }).sort((a, b) => a.name.localeCompare(b.name))
            }
        }
    }
}

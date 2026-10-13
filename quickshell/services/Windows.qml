pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property bool nothingFocused: false
    readonly property HyprlandToplevel focused: nothingFocused ? null : Hyprland.activeToplevel

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activewindowv2")
                root.nothingFocused = event.data === ""
        }
    }

    function target(window) {
        return `address:0x${window.address}`
    }

    function lua(name, window, args) {
        const fields = [`window = "${root.target(window)}"`]
        for (const [key, value] of Object.entries(args ?? {}))
            fields.push(`${key} = ${JSON.stringify(value)}`)
        Hyprland.dispatch(`hl.dsp.${name}({ ${fields.join(", ")} })`)
    }

    function focus(window) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("focus", window)
        else
            Hyprland.dispatch(`focuswindow ${root.target(window)}`)
    }

    function close(window) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("window.close", window)
        else
            Hyprland.dispatch(`closewindow ${root.target(window)}`)
    }

    function toggleFloating(window) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("window.float", window, { action: "toggle" })
        else
            Hyprland.dispatch(`togglefloating ${root.target(window)}`)
    }

    function togglePin(window) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("window.pin", window, { action: "toggle" })
        else
            Hyprland.dispatch(`pin ${root.target(window)}`)
    }

    function toggleFullscreen(window, mode) {
        if (!window) return
        if (Hyprland.usingLua) {
            root.lua("window.fullscreen", window, { action: "toggle", mode })
        } else {
            Quickshell.execDetached(["hyprctl", "--batch",
                `dispatch focuswindow ${root.target(window)}; dispatch fullscreen ${mode === "maximized" ? 1 : 0}`])
        }
    }

    function floatCentered(window, width, height) {
        if (!window) return
        const w = root.target(window)
        const steps = Hyprland.usingLua
            ? [`hl.dsp.window.float({ window = "${w}", action = "enable" })`,
               `hl.dsp.window.resize({ window = "${w}", x = ${width}, y = ${height} })`,
               `hl.dsp.window.center({ window = "${w}" })`]
            : [`setfloating ${w}`, `resizewindowpixel exact ${width} ${height},${w}`, `focuswindow ${w}`, "centerwindow"]
        Quickshell.execDetached(["hyprctl", "--batch", steps.map(s => "dispatch " + s).join("; ")])
    }

    function moveToWorkspace(window, workspace) {
        if (!window) return
        if (Hyprland.usingLua)
            root.lua("window.move", window, { workspace, follow: false })
        else
            Hyprland.dispatch(`movetoworkspacesilent ${workspace},${root.target(window)}`)
    }
}

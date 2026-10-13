import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.bar
import qs.config
import qs.notifications
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens

        delegate: StudyBar {}
    }

    Toasts {}

    IpcHandler {
        target: "startmenu"

        function toggle(): void {
            Popups.startMenuRequested(Hyprland.focusedMonitor?.name ?? "")
        }
    }

    IpcHandler {
        target: "theme"

        function set(id: string): void {
            Theme.setTheme(id)
        }

        function light(): void {
            Theme.setDark(false)
        }

        function dark(): void {
            Theme.setDark(true)
        }

        function toggleMode(): void {
            Theme.setDark(!Theme.dark)
        }

        function list(): string {
            return Theme.themes.map(t => (t.id === Theme.current ? "* " : "  ") + t.id + "  (" + t.name + ")").join("\n")
        }
    }

    IpcHandler {
        target: "study"

        function capture(): void {
            Emacs.capture()
        }

        function update(json: string): void {
            Emacs.receive(json)
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            Notifs.dnd = !Notifs.dnd
        }

        function clear(): void {
            Notifs.clear()
        }
    }
}

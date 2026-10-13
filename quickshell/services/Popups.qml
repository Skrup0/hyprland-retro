pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var current: null

    signal startMenuRequested(string screenName)

    function open(popup) {
        root.current = popup
    }

    function close() {
        root.current = null
    }

    function toggle(popup) {
        root.current = root.current === popup ? null : popup
    }
}

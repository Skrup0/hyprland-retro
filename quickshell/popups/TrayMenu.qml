import QtQuick
import qs.components

BarPopup {
    id: popup

    property var handle

    padding: 2
    spacing: 0

    MenuEntries {
        handle: popup.handle
        open: popup.shown
        onTriggered: popup.close()
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: popup

    required property Item anchorItem
    property int align: Qt.AlignHCenter
    property int padding: 8
    property alias spacing: body.spacing

    readonly property bool shown: Popups.current === popup
    readonly property var barWindow: anchorItem.QsWindow.window
    readonly property bool fromBottom: barWindow?.anchors.bottom === true && barWindow?.anchors.top !== true

    default property alias content: body.data

    function toggle() {
        Popups.toggle(popup)
    }

    function close() {
        if (shown)
            Popups.close()
    }

    function reposition() {
        const x = anchorItem.mapToItem(null, 0, 0).x
        const w = implicitWidth
        const left = align === Qt.AlignLeft ? x
                   : align === Qt.AlignRight ? x + anchorItem.width - w
                   : x + (anchorItem.width - w) / 2
        margins.left = Math.round(Math.max(0, Math.min(left, (screen?.width ?? left + w) - w)))
    }

    onShownChanged: {
        if (shown)
            reposition()
        else
            settled = false
    }
    onImplicitWidthChanged: if (shown) reposition()

    screen: barWindow?.screen ?? null
    visible: shown
    color: "transparent"
    implicitWidth: body.implicitWidth + padding * 2 + 2
    implicitHeight: body.implicitHeight + padding * 2 + 2

    anchors {
        top: !popup.fromBottom
        bottom: popup.fromBottom
        left: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "retrobar-popup"
    property bool settled: false
    WlrLayershell.keyboardFocus: shown && !settled ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    Connections {
        target: body.Window.window
        enabled: popup.shown && !popup.settled

        function onFrameSwapped() {
            popup.settled = true
        }
    }

    Timer {
        running: popup.shown && !popup.settled
        interval: 300
        onTriggered: popup.settled = true
    }

    LazyLoader {
        active: popup.shown

        PanelWindow {
            screen: popup.screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "retrobar-catcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: popup.close()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.window
        border.width: 1
        border.color: Theme.windowBorder
        focus: true
        Keys.onEscapePressed: popup.close()

        ColumnLayout {
            id: body

            anchors.fill: parent
            anchors.margins: popup.padding + 1
            spacing: 6
        }
    }
}

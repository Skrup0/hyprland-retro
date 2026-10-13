import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

Item {
    id: root

    required property Notification modelData
    property bool highlight: false

    readonly property string appName: modelData?.appName ?? ""
    readonly property string summary: modelData?.summary ?? ""
    readonly property string body: modelData?.body ?? ""
    readonly property string image: modelData?.image ?? ""
    readonly property string appIcon: modelData?.appIcon ?? ""
    readonly property var actions: modelData ? [...modelData.actions] : []
    readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical

    readonly property string iconSource: image !== ""
        ? image
        : appIcon !== "" ? Quickshell.iconPath(appIcon, true) : ""

    readonly property alias hovered: hover.hovered

    implicitHeight: column.implicitHeight + 6
    implicitWidth: 300

    HoverHandler {
        id: hover
    }

    Bevel {
        anchors.fill: parent
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 3
        spacing: 0

        Rectangle {
            id: titleBar

            readonly property color textColor: root.critical || root.highlight ? Theme.selectionText : Theme.titleInactiveText

            Layout.fillWidth: true
            implicitHeight: 18
            color: root.critical ? Theme.warning : root.highlight ? Theme.selection : Theme.titleInactive

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 1
                spacing: 4

                BarText {
                    Layout.fillWidth: true
                    text: root.appName !== "" ? root.appName : "Notification"
                    font.bold: true
                    color: titleBar.textColor
                }

                BarButton {
                    implicitWidth: 16
                    implicitHeight: 14
                    text: "x"
                    onClicked: root.modelData?.dismiss()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: bodyRow.implicitHeight + 12

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!root.modelData) return
                    Notifs.activate(root.modelData)
                    Notifs.hideToast(root.modelData)
                }
            }

            RowLayout {
                id: bodyRow

                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                IconImage {
                    Layout.alignment: Qt.AlignTop
                    visible: root.iconSource !== ""
                    source: root.iconSource
                    implicitSize: 32
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    BarText {
                        Layout.fillWidth: true
                        text: root.summary
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }

                    BarText {
                        Layout.fillWidth: true
                        visible: root.body !== ""
                        text: root.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 6
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textDim
                        linkColor: Theme.text
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
        }

        RowLayout {
            readonly property var actions: root.actions.filter(a => a.identifier !== "default")

            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 6
            visible: actions.length > 0
            spacing: 4

            Repeater {
                model: parent.actions

                delegate: BarButton {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 20
                    text: modelData?.text ?? ""
                    onClicked: modelData?.invoke()
                }
            }
        }
    }
}

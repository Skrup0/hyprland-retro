import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property var handle
    property bool open: false
    property var stack: []

    readonly property var currentMenu: stack.length > 0 ? stack[stack.length - 1] : handle
    readonly property bool inSubmenu: stack.length > 0
    readonly property bool anyChecks: [...opener.children.values].some(e => e.buttonType !== QsMenuButtonType.None)

    signal triggered()

    Layout.fillWidth: true
    spacing: 0
    onOpenChanged: stack = []

    QsMenuOpener {
        id: opener
        menu: root.open ? root.currentMenu : null
    }

    MenuRow {
        visible: root.inSubmenu
        text: "◄ " + (root.inSubmenu ? root.stack[root.stack.length - 1].text : "")
        bold: true
        onClicked: root.stack = root.stack.slice(0, -1)
    }

    Separator {
        visible: root.inSubmenu
        vertical: false
    }

    Repeater {
        model: opener.children

        delegate: Item {
            id: entry

            required property QsMenuEntry modelData

            Layout.fillWidth: true
            Layout.minimumWidth: 160
            implicitWidth: modelData.isSeparator ? 0 : row.implicitWidth
            implicitHeight: modelData.isSeparator ? 6 : row.implicitHeight

            Separator {
                anchors.fill: parent
                visible: entry.modelData.isSeparator
                vertical: false
            }

            MenuRow {
                id: row

                width: parent.width
                visible: !entry.modelData.isSeparator
                enabled: entry.modelData.enabled
                text: entry.modelData.text.replace(/_(.)/g, "$1")
                icon: entry.modelData.icon
                hint: entry.modelData.hasChildren ? "►" : ""
                checkType: entry.modelData.buttonType === QsMenuButtonType.CheckBox ? 1
                         : entry.modelData.buttonType === QsMenuButtonType.RadioButton ? 2 : 0
                checked: entry.modelData.checkState === Qt.Checked
                reserveCheck: root.anyChecks

                onClicked: {
                    if (entry.modelData.hasChildren) {
                        root.stack = [...root.stack, entry.modelData]
                    } else {
                        entry.modelData.triggered()
                        root.triggered()
                    }
                }
            }
        }
    }
}

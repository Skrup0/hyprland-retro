import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarPopup {
    id: popup

    property string query: ""

    readonly property var tasks: {
        const order = t => [t.keyword === "IN-PROGRESS" ? 0 : t.keyword === "WAITING" ? 2 : 1,
                            t.priority || "Z", t.deadline ?? Infinity]
        const q = query.trim().toLowerCase()
        return Org.tasks
            .filter(t => q === "" || [t.heading, t.category, ...t.tags].join(" ").toLowerCase().includes(q))
            .sort((a, b) => {
                const x = order(a), y = order(b)
                for (let i = 0; i < x.length; i++)
                    if (x[i] !== y[i]) return x[i] < y[i] ? -1 : 1
                return a.heading.localeCompare(b.heading)
            })
    }

    function hint(task) {
        const due = task.deadline !== null ? " · " + Org.dueText(task, Date.now() / 1000) : ""
        return `${task.category}${task.priority ? " #" + task.priority : ""}${due}`
    }

    function choose(task, mouse) {
        if (mouse.button === Qt.RightButton)
            Emacs.open(task)
        else
            Study.pick(task)
        close()
    }

    align: Qt.AlignLeft
    padding: 4
    implicitWidth: 460

    onShownChanged: {
        if (!shown) return
        Org.rescan()
        search.text = ""
        list.currentIndex = 0
        search.focusInput()
    }

    PopupHeader {
        text: "Org tasks"

        BarButton {
            implicitHeight: 20
            text: "Agenda"
            onClicked: {
                Emacs.agenda()
                popup.close()
            }
        }

        BarButton {
            implicitHeight: 20
            text: "Capture"
            onClicked: {
                Emacs.capture()
                popup.close()
            }
        }
    }

    TextField {
        id: search

        Layout.fillWidth: true
        placeholder: "Filter..."
        onTextChanged: {
            popup.query = text
            list.currentIndex = 0
        }
        onAccepted: {
            const task = popup.tasks[list.currentIndex]
            if (task) {
                Study.pick(task)
                popup.close()
            }
        }
        onDownPressed: list.incrementCurrentIndex()
        onUpPressed: list.decrementCurrentIndex()
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: Math.min(popup.tasks.length, 16) * 20 + 4

        Bevel {
            anchors.fill: parent
            sunken: true
            faceColor: Theme.field
        }

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: popup.tasks

            delegate: MenuRow {
                required property var modelData
                required property int index

                width: ListView.view.width
                text: (modelData.keyword === "IN-PROGRESS" ? "▸ " : "") + modelData.heading
                hint: popup.hint(modelData)
                checkType: 2
                checked: Emacs.clocking && modelData.heading === Emacs.task && modelData.file === Emacs.file
                highlighted: ListView.isCurrentItem
                onHoveredChanged: if (hovered) list.currentIndex = index
                onClicked: mouse => popup.choose(modelData, mouse)
            }
        }
    }

    BarText {
        visible: popup.tasks.length === 0
        text: Org.tasks.length === 0 ? "No open tasks in your org files" : "Nothing matches"
        color: Theme.textMuted
    }

    BarText {
        text: "Click: pomodoro · Right click: open in Emacs"
        color: Theme.textMuted
        font.pixelSize: Theme.fontSizeSmall
    }
}

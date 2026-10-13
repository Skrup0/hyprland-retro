import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

BarButton {
    id: root

    readonly property var cards: Org.cards

    visible: cards.total > 0
    flat: true
    implicitWidth: lcd.implicitWidth + 4
    tooltip: "Click to review"
    onClicked: Emacs.review()

    LcdPanel {
        id: lcd

        anchors.centerIn: parent
        label: "FLASHCARDS"
        readout: `${root.cards.review}/${root.cards.total}`
        readoutSample: "888/888"
    }
}

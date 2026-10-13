import QtQuick
import qs.config

Canvas {
    id: root

    property string kind: "play"
    readonly property color ink: Theme.text

    implicitWidth: 10
    implicitHeight: 10

    onInkChanged: requestPaint()
    onKindChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = ink

        const triangle = (x, w, left) => {
            ctx.beginPath()
            ctx.moveTo(left ? x + w : x, 0)
            ctx.lineTo(left ? x : x + w, 5)
            ctx.lineTo(left ? x + w : x, 10)
            ctx.closePath()
            ctx.fill()
        }

        switch (kind) {
        case "play":
            triangle(1, 8, false)
            break
        case "pause":
            ctx.fillRect(1, 0, 3, 10)
            ctx.fillRect(6, 0, 3, 10)
            break
        case "stop":
            ctx.fillRect(1, 1, 8, 8)
            break
        case "next":
            triangle(0, 7, false)
            ctx.fillRect(8, 0, 2, 10)
            break
        case "previous":
            ctx.fillRect(0, 0, 2, 10)
            triangle(3, 7, true)
            break
        }
    }
}

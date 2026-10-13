import QtQuick
import qs.config

Canvas {
    id: root

    property var values: []
    property int step: 2
    property int gridSize: 6

    property int scroll: 0
    readonly property var colors: [Theme.lcd, Theme.lcdOn, Theme.lcdGrid]

    implicitWidth: 40
    implicitHeight: 14

    onValuesChanged: {
        scroll = (scroll + step) % gridSize
        requestPaint()
    }
    onColorsChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        const w = Math.round(width)
        const h = Math.round(height)
        ctx.reset()
        ctx.fillStyle = Theme.lcd
        ctx.fillRect(0, 0, w, h)

        ctx.fillStyle = Theme.lcdGrid
        for (let x = w - 1 - scroll; x >= 0; x -= gridSize)
            ctx.fillRect(x, 0, 1, h)
        for (let y = h - 1; y >= 0; y -= gridSize)
            ctx.fillRect(0, y, w, 1)

        ctx.fillStyle = Theme.lcdOn
        const n = values.length
        for (let i = 0; i < n; i++) {
            const x = w - (i + 1) * step
            if (x + step <= 0) break
            const top = h - Math.max(1, Math.round(Math.min(1, Math.max(0, values[n - 1 - i])) * h))
            ctx.globalAlpha = 0.35
            ctx.fillRect(x, top, step, h - top)
            ctx.globalAlpha = 1
            ctx.fillRect(x, top, step, 1)
        }
    }
}

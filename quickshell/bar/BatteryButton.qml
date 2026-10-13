import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.popups

BarButton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.PendingCharge
        || device.state === UPowerDeviceState.FullyCharged

    visible: device.ready && device.isLaptopBattery
    implicitWidth: batteryIcon.width + 4 + percent.implicitWidth + 12
    active: popup.shown
    onClicked: popup.toggle()

    BatteryIcon {
        id: batteryIcon

        x: Math.round((parent.width - (width + 4 + percent.implicitWidth)) / 2)
        y: Math.round((parent.height - height) / 2)
        level: root.device.percentage
        charging: root.charging
    }

    BarText {
        id: percent

        anchors.left: batteryIcon.right
        anchors.leftMargin: 4
        y: Math.ceil((parent.height - height) / 2)
        text: Math.round(root.device.percentage * 100) + "%"
    }

    BatteryPopup {
        id: popup
        anchorItem: root
        align: Qt.AlignRight
    }
}

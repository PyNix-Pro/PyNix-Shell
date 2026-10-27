import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: batteryService

    readonly property var battery: findBattery()
    readonly property bool available: battery !== null && battery.ready &&
        battery.isPresent && isFinite(Number(battery.percentage))
    readonly property int percentage: available
        ? Math.max(0, Math.min(100, Math.round(Number(battery.percentage))))
        : 0
    readonly property string status: !available ? "Unavailable"
        : battery.state === UPowerDeviceState.Charging ? "Charging"
        : battery.state === UPowerDeviceState.Discharging ? "Discharging"
        : battery.state === UPowerDeviceState.FullyCharged ? "Fully charged"
        : battery.state === UPowerDeviceState.PendingCharge ? "Charging soon"
        : battery.state === UPowerDeviceState.PendingDischarge ? "Discharging soon"
        : battery.state === UPowerDeviceState.Empty ? "Empty"
        : "State unknown"

    function findBattery() {
        var devices = UPower.devices.values
        for (var index = 0; index < devices.length; index++) {
            var device = devices[index]
            if (device.isLaptopBattery && device.ready && device.isPresent)
                return device
        }
        return null
    }
}

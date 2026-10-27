import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: bluetoothService

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property string adapterName: available ? adapter.name : ""
    readonly property var connectedDevices: available
        ? adapter.devices.values.filter(function(device) { return device.connected })
        : []
    readonly property int connectedDeviceCount: connectedDevices.length
    readonly property string status: !available ? "Unavailable"
        : !enabled ? "Disabled"
        : operationPending ? operationLabel
        : connectedDeviceCount > 0 ? "Connected"
        : "Enabled; no connected devices"

    property bool operationPending: false
    property string operationLabel: ""
    property string operationTarget: ""
    property bool requestedEnabled: false
    property var pendingDevice: null
    property bool requestedDeviceConnection: false
    property string failureMessage: ""
    signal stateChanged()

    function toggle() {
        if (!available) {
            failureMessage = "No BlueZ Bluetooth adapter is available."
            return false
        }
        failureMessage = ""
        requestedEnabled = !adapter.enabled
        if (requestedEnabled === adapter.enabled)
            return true
        operationPending = true
        operationTarget = "adapter"
        operationLabel = requestedEnabled ? "Enabling" : "Disabling"
        adapter.enabled = requestedEnabled
        return true
    }

    function toggleDevice(device) {
        if (!available || !device) {
            failureMessage = "The selected Bluetooth device is unavailable."
            return false
        }
        failureMessage = ""
        pendingDevice = device
        requestedDeviceConnection = !device.connected
        if (requestedDeviceConnection === device.connected)
            return true
        operationPending = true
        operationTarget = "device"
        operationLabel = requestedDeviceConnection ? "Connecting device" : "Disconnecting device"
        device.connected = requestedDeviceConnection
        return true
    }

    function confirmAdapterState() {
        if (operationPending && operationTarget === "adapter" && adapter &&
                adapter.enabled === requestedEnabled) {
            operationPending = false
            operationLabel = ""
            operationTarget = ""
            failureMessage = ""
            stateChanged()
        }
    }

    function confirmDeviceState() {
        if (operationPending && operationTarget === "device" && pendingDevice &&
                pendingDevice.connected === requestedDeviceConnection) {
            operationPending = false
            operationLabel = ""
            operationTarget = ""
            pendingDevice = null
            failureMessage = ""
            stateChanged()
        }
    }

    Connections {
        target: bluetoothService.adapter
        ignoreUnknownSignals: true
        function onEnabledChanged() {
            bluetoothService.confirmAdapterState()
        }
    }

    Connections {
        target: bluetoothService.pendingDevice
        ignoreUnknownSignals: true
        function onConnectedChanged() {
            bluetoothService.confirmDeviceState()
        }
    }

    Timer {
        interval: 8000
        repeat: false
        running: bluetoothService.operationPending
        onTriggered: {
            if (bluetoothService.operationPending) {
                bluetoothService.operationPending = false
                bluetoothService.operationLabel = ""
                bluetoothService.operationTarget = ""
                bluetoothService.pendingDevice = null
                bluetoothService.failureMessage =
                    "Bluetooth operation was not confirmed; check adapter availability and permissions."
                bluetoothService.stateChanged()
            }
        }
    }
}

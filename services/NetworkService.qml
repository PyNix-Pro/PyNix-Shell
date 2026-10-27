import QtQuick
import Quickshell.Networking

QtObject {
    id: networkService

    readonly property var wifiDevice: findWifiDevice()
    readonly property bool available: wifiDevice !== null
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool enabled: available && Networking.wifiEnabled
    readonly property var networks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var connectedNetwork: findConnectedNetwork()
    readonly property bool connected: connectedNetwork !== null
    readonly property bool connecting: hasNetworkTransition()
    readonly property string ssid: connected ? connectedNetwork.name : ""
    readonly property string status: !available ? "Unavailable"
        : !hardwareEnabled ? "Blocked by hardware"
        : !enabled ? "Disabled"
        : operationPending && operationDisconnecting ? "Disconnecting"
        : operationPending || connecting ? "Connecting"
        : connected ? "Connected"
        : "Disconnected"

    property var selectedNetwork: connectedNetwork
    property bool operationPending: false
    property bool operationDisconnecting: false
    property bool credentialRequired: false
    property string failureMessage: ""
    signal stateChanged()

    function findWifiDevice() {
        var devices = Networking.devices.values
        for (var index = 0; index < devices.length; index++) {
            if (devices[index].type === DeviceType.Wifi)
                return devices[index]
        }
        return null
    }

    function findConnectedNetwork() {
        var availableNetworks = networks
        for (var index = 0; index < availableNetworks.length; index++) {
            if (availableNetworks[index].connected)
                return availableNetworks[index]
        }
        return null
    }

    function hasNetworkTransition() {
        var availableNetworks = networks
        for (var index = 0; index < availableNetworks.length; index++) {
            if (availableNetworks[index].stateChanging)
                return true
        }
        return false
    }

    function networkNeedsPsk(network) {
        if (!network)
            return false
        return network.security === WifiSecurityType.WpaPsk ||
                network.security === WifiSecurityType.Wpa2Psk ||
                network.security === WifiSecurityType.Sae
    }

    function toggleWifi() {
        if (!available) {
            failureMessage = "No NetworkManager Wi-Fi device is available."
            return false
        }
        failureMessage = ""
        credentialRequired = false
        operationPending = false
        operationDisconnecting = false
        Networking.wifiEnabled = !Networking.wifiEnabled
        return true
    }

    function connectTo(network, password) {
        if (!available || !network) {
            failureMessage = "Select an available Wi-Fi network first."
            return false
        }

        selectedNetwork = network
        failureMessage = ""
        if (network.connected) {
            operationPending = true
            operationDisconnecting = true
            network.disconnect()
            return true
        }

        if (!enabled) {
            failureMessage = "Enable Wi-Fi before connecting."
            return false
        }

        if (networkNeedsPsk(network) && !network.known && !password) {
            credentialRequired = true
            failureMessage = "Enter this network's password to connect."
            return false
        }

        if (networkNeedsPsk(network) && password) {
            credentialRequired = false
            operationPending = true
            operationDisconnecting = false
            network.connectWithPsk(password)
            return true
        }

        if (network.security !== WifiSecurityType.Open &&
                !network.known) {
            failureMessage = "This network's authentication type is not supported by this control."
            return false
        }

        credentialRequired = false
        operationPending = true
        operationDisconnecting = false
        network.connect()
        return true
    }

    function handleConnectionFailure(reason) {
        operationPending = false
        operationDisconnecting = false
        if (reason === ConnectionFailReason.NoSecrets) {
            credentialRequired = true
            failureMessage = "Authentication required. Enter the network password."
        } else {
            credentialRequired = false
            failureMessage = "Connection failed: " + ConnectionFailReason.toString(reason)
        }
        stateChanged()
    }

    onConnectedChanged: {
        if (connected) {
            operationPending = false
            operationDisconnecting = false
            credentialRequired = false
            failureMessage = ""
        }
        stateChanged()
    }
    onEnabledChanged: {
        if (!enabled) {
            operationPending = false
            operationDisconnecting = false
            credentialRequired = false
        }
        stateChanged()
    }
    onHardwareEnabledChanged: {
        if (!hardwareEnabled) {
            operationPending = false
            operationDisconnecting = false
            credentialRequired = false
        }
        stateChanged()
    }

    Connections {
        target: networkService.selectedNetwork
        ignoreUnknownSignals: true

        function onConnectionFailed(reason) {
            networkService.handleConnectionFailure(reason)
        }
        function onStateChanged() {
            if (networkService.selectedNetwork &&
                    networkService.selectedNetwork.connected) {
                networkService.operationPending = false
                networkService.operationDisconnecting = false
                networkService.credentialRequired = false
                networkService.failureMessage = ""
            } else if (networkService.operationPending &&
                    networkService.operationDisconnecting &&
                    networkService.selectedNetwork &&
                    networkService.selectedNetwork.state === ConnectionState.Disconnected) {
                networkService.operationPending = false
                networkService.operationDisconnecting = false
            }
        }
    }

    Timer {
        interval: 30000
        repeat: false
        running: networkService.operationPending
        onTriggered: {
            if (networkService.operationPending) {
                networkService.operationPending = false
                networkService.operationDisconnecting = false
                networkService.failureMessage = "The network operation timed out; system state was not confirmed."
                networkService.stateChanged()
            }
        }
    }
}

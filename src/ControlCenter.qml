import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: controlCenter

    required property var settings
    required property var themeService
    required property var audioService
    required property var mediaService
    required property var networkService
    required property var bluetoothService
    required property var brightnessService
    required property var notificationService
    required property var applicationService
    signal settingsRequested()
    signal launcherRequested()
    signal closeRequested()

    width: Math.max(0, Math.min(settings.controlCenter.width, parent.width - 24))
    height: Math.min(settings.controlCenter.height, parent.height - y - 8)
    x: parent.width - width - 18
    y: 62
    radius: settings.controlCenter.radius
    color: themeService.palette.surface
    border.width: 1
    border.color: themeService.palette.border
    clip: true
    onVisibleChanged: {
        brightnessService.setMonitoring(controlCenter, visible)
    }
    Component.onCompleted: {
        if (visible)
            brightnessService.setMonitoring(controlCenter, true)
    }
    Component.onDestruction: {
        brightnessService.setMonitoring(controlCenter, false)
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        GridLayout {
            width: controlCenter.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            columns: 2
            columnSpacing: 8
            rowSpacing: 10

            RowLayout {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: "Control Center"
                    color: themeService.palette.primaryText
                    font.pixelSize: 18
                    font.bold: true
                }
                ToolButton {
                    text: "Apps"
                    Accessible.name: "Open application launcher"
                    onClicked: controlCenter.launcherRequested()
                }
                ToolButton {
                    text: "⚙"
                    Accessible.name: "Open Settings"
                    onClicked: controlCenter.settingsRequested()
                }
                ToolButton {
                    text: "×"
                    Accessible.name: "Close Control Center"
                    onClicked: controlCenter.closeRequested()
                }
            }

            Repeater {
                model: settings.currentTiles()

                delegate: Loader {
                    id: tileLoader
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.row: modelData.gridRow
                    Layout.column: modelData.gridColumn
                    Layout.columnSpan: modelData.size === "compact" ? 1 : 2
                    Layout.preferredHeight: settings.tileHeight(modelData.size, modelData.id)
                    property var tileData: modelData
                    sourceComponent: tileData.id === "audio" ? audioTile
                        : tileData.id === "media" ? mediaTile
                        : tileData.id === "appearance" ? appearanceTile
                        : tileData.id === "motion" ? motionTile
                        : tileData.id === "wifi" ? wifiTile
                        : tileData.id === "bluetooth" ? bluetoothTile
                        : tileData.id === "brightness" ? brightnessTile
                        : tileData.id === "notifications" ? notificationsTile : unavailableTile
                }
            }
        }
    }

    Component {
        id: audioTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: audioService.available ? "Output volume" : "PipeWire output unavailable"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                    }
                    ToolButton {
                        text: audioService.muted ? "Muted" : "Mute"
                        enabled: audioService.available
                        onClicked: audioService.toggleMute()
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: audioService.volume
                    enabled: audioService.available
                    onMoved: audioService.setVolume(value)
                }
                Label {
                    text: audioService.available
                        ? Math.round(audioService.volume * 100) + "%"
                        : "No writable output device was detected"
                    color: themeService.palette.secondaryText
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: mediaTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: mediaService.available ? mediaService.title : "No MPRIS player"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: mediaService.available ? mediaService.artist : "Start a media player with MPRIS support"
                        color: themeService.palette.secondaryText
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
                ToolButton {
                    text: "⏮"
                    enabled: mediaService.canGoPrevious
                    onClicked: mediaService.previous()
                }
                ToolButton {
                    text: mediaService.playing ? "⏸" : "▶"
                    enabled: mediaService.canTogglePlaying
                    onClicked: mediaService.playPause()
                }
                ToolButton {
                    text: "⏭"
                    enabled: mediaService.canGoNext
                    onClicked: mediaService.next()
                }
            }
        }
    }

    Component {
        id: appearanceTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                Label {
                    Layout.fillWidth: true
                    text: "Theme"
                    color: themeService.palette.primaryText
                    font.weight: Font.DemiBold
                }
                ComboBox {
                    model: ["material-you", "nightfox", "noir", "desert", "ocean", "rose"]
                    currentIndex: Math.max(0, model.indexOf(settings.theme))
                    onActivated: settings.theme = currentText
                }
            }
        }
    }

    Component {
        id: motionTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0
                CheckBox {
                    text: "Reduced motion"
                    checked: settings.motion.reducedMotion
                    onToggled: settings.motion.reducedMotion = checked
                }
                CheckBox {
                    text: "Low-performance mode"
                    checked: settings.motion.lowPerformance
                    onToggled: settings.motion.lowPerformance = checked
                }
            }
        }
    }

    Component {
        id: wifiTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                    }
                    Switch {
                        checked: networkService.enabled
                        enabled: networkService.available && networkService.hardwareEnabled
                        onToggled: networkService.toggleWifi()
                        Accessible.name: "Enable Wi-Fi"
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: networkService.connected
                        ? networkService.status + " — " + networkService.ssid
                        : networkService.status
                    color: networkService.failureMessage
                        ? themeService.palette.error
                        : !networkService.available ? themeService.palette.mutedText
                            : networkService.connected ? themeService.palette.success
                                : themeService.palette.secondaryText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                ComboBox {
                    id: wifiNetworkSelector
                    Layout.fillWidth: true
                    model: networkService.networks
                    textRole: "name"
                    enabled: networkService.available && networkService.enabled
                    currentIndex: {
                        var values = networkService.networks
                        var selected = networkService.selectedNetwork || networkService.connectedNetwork
                        return selected ? values.indexOf(selected) : -1
                    }
                    onActivated: {
                        networkService.selectedNetwork = networkService.networks[currentIndex]
                        networkService.credentialRequired = false
                        networkService.failureMessage = ""
                    }
                }
                TextField {
                    id: wifiPassword
                    Layout.fillWidth: true
                    visible: networkService.credentialRequired
                    placeholderText: "Network password"
                    echoMode: TextInput.Password
                    Accessible.name: "Wi-Fi network password"
                    onVisibleChanged: {
                        if (!visible)
                            clear()
                    }
                    onAccepted: {
                        if (networkService.connectTo(networkService.selectedNetwork, text))
                            clear()
                    }
                }
                Button {
                    Layout.alignment: Qt.AlignRight
                    text: networkService.selectedNetwork &&
                            networkService.selectedNetwork.connected ? "Disconnect" : "Connect"
                    enabled: networkService.available && networkService.enabled &&
                            networkService.selectedNetwork !== null &&
                            !networkService.operationPending
                    onClicked: {
                        if (networkService.connectTo(networkService.selectedNetwork, wifiPassword.text))
                            wifiPassword.clear()
                    }
                }
                Label {
                    Layout.fillWidth: true
                    visible: networkService.failureMessage.length > 0
                    text: networkService.failureMessage
                    color: themeService.palette.error
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component {
        id: bluetoothTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: bluetoothService.available
                            ? "Bluetooth — " + bluetoothService.adapterName : "Bluetooth"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Switch {
                        checked: bluetoothService.enabled
                        enabled: bluetoothService.available && !bluetoothService.operationPending
                        onToggled: bluetoothService.toggle()
                        Accessible.name: "Enable Bluetooth"
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: bluetoothService.failureMessage || bluetoothService.status
                    color: bluetoothService.failureMessage
                        ? themeService.palette.error
                        : !bluetoothService.available ? themeService.palette.mutedText
                            : bluetoothService.enabled ? themeService.palette.success
                                : themeService.palette.secondaryText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Repeater {
                    model: bluetoothService.connectedDevices.slice(0, 2)
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.deviceName || "Bluetooth device"
                            color: themeService.palette.primaryText
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        ToolButton {
                            text: "Disconnect"
                            enabled: !bluetoothService.operationPending
                            onClicked: bluetoothService.toggleDevice(modelData)
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    visible: bluetoothService.connectedDeviceCount > 2
                    text: "+" + (bluetoothService.connectedDeviceCount - 2) + " more connected"
                    color: themeService.palette.mutedText
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: brightnessTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Display brightness"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: brightnessService.available
                            ? Math.round(brightnessService.value * 100) + "%"
                            : brightnessService.status
                        color: brightnessService.failureMessage
                            ? themeService.palette.error
                            : brightnessService.available ? themeService.palette.secondaryText
                                : themeService.palette.mutedText
                        font.pixelSize: 10
                    }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: brightnessService.value
                    enabled: brightnessService.available
                    onMoved: brightnessService.setValue(value)
                    Accessible.name: "Display brightness"
                }
                Label {
                    Layout.fillWidth: true
                    visible: brightnessService.failureMessage.length > 0
                    text: brightnessService.failureMessage
                    color: themeService.palette.error
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component {
        id: notificationsTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Notifications (" + notificationService.count + ")"
                        color: themeService.palette.primaryText
                        font.weight: Font.DemiBold
                    }
                    ToolButton {
                        text: "Clear"
                        enabled: notificationService.count > 0
                        Accessible.name: "Dismiss all active notifications"
                        onClicked: notificationService.clearAll()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: notificationService.count === 0
                    text: "No active notifications."
                    color: themeService.palette.secondaryText
                    verticalAlignment: Text.AlignVCenter
                }

                ListView {
                    id: notificationList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: notificationService.count > 0
                    clip: true
                    spacing: 5
                    model: notificationService.notifications.slice(0, settings.notifications.maxVisible)

                    delegate: Rectangle {
                        required property var modelData
                        width: notificationList.width
                        height: 62
                        radius: 10
                        color: themeService.palette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName
                                        ? modelData.appName + ": " + modelData.summary
                                        : modelData.summary
                                    color: themeService.palette.primaryText
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.body
                                    color: themeService.palette.secondaryText
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }

                            ToolButton {
                                text: "×"
                                Accessible.name: "Dismiss notification"
                                onClicked: notificationService.dismiss(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: unavailableTile
        Rectangle {
            radius: 16
            color: themeService.palette.secondarySurface
            border.color: themeService.palette.border
            Label {
                anchors.centerIn: parent
                text: "This tile is not implemented."
                color: themeService.palette.secondaryText
            }
        }
    }
}

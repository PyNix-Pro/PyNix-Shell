import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

ShellRoot {
    id: shell

    property var currentTime: new Date()
    property bool settingsOpen: false
    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool islandExpanded: false
    property string settingsPage: "bar"

    SettingsService { id: settingsService }
    ThemeService { id: themeService }
    MediaService { id: mediaService }
    AudioService { id: audioService }
    NetworkService { id: networkService }
    BluetoothService { id: bluetoothService }
    BatteryService { id: batteryService }
    BrightnessService { id: brightnessService }
    ApplicationService {
        id: applicationService
        settings: settingsService
    }
    NotificationService { id: notificationService }

    function indicatorAvailable(indicatorId) {
        if (indicatorId === "network")
            return networkService.available
        if (indicatorId === "bluetooth")
            return bluetoothService.available
        if (indicatorId === "audio")
            return audioService.available
        if (indicatorId === "battery")
            return batteryService.available
        return false
    }

    function indicatorLabel(indicatorId) {
        if (indicatorId === "network")
            return networkService.available ? "W" : "-"
        if (indicatorId === "bluetooth")
            return bluetoothService.available ? "B" : "-"
        if (indicatorId === "audio")
            return !audioService.available ? "-" : audioService.muted ? "x" : "A"
        if (indicatorId === "battery")
            return batteryService.available ? String(batteryService.percentage) : ""
        return "-"
    }

    function indicatorDescription(indicatorId) {
        if (indicatorId === "network")
            return networkService.failureMessage
                ? "Wi-Fi: " + networkService.failureMessage
                : "Wi-Fi: " + networkService.status +
                    (networkService.connected && networkService.ssid ? " (" + networkService.ssid + ")" : "")
        if (indicatorId === "bluetooth")
            return bluetoothService.failureMessage
                ? "Bluetooth: " + bluetoothService.failureMessage
                : "Bluetooth: " + bluetoothService.status
        if (indicatorId === "audio")
            return audioService.available
                ? audioService.muted ? "Audio output muted" : "Audio output available"
                : "Audio output unavailable"
        if (indicatorId === "battery")
            return batteryService.available
                ? "Battery: " + batteryService.percentage + "%, " + batteryService.status
                : "Battery information unavailable"
        return ""
    }

    function indicatorColor(indicatorId) {
        if (indicatorId === "network") {
            if (networkService.failureMessage)
                return themeService.palette.error
            if (networkService.connected)
                return themeService.palette.success
            if (networkService.enabled)
                return themeService.palette.accent
            return themeService.palette.mutedText
        }
        if (indicatorId === "bluetooth") {
            if (bluetoothService.failureMessage)
                return themeService.palette.error
            if (!bluetoothService.available || !bluetoothService.enabled)
                return themeService.palette.mutedText
            return bluetoothService.connectedDeviceCount > 0
                ? themeService.palette.success : themeService.palette.accent
        }
        if (indicatorId === "audio") {
            if (!audioService.available)
                return themeService.palette.mutedText
            return audioService.muted ? themeService.palette.warning : themeService.palette.success
        }
        if (indicatorId === "battery") {
            if (!batteryService.available)
                return themeService.palette.mutedText
            if (batteryService.status === "Charging")
                return themeService.palette.success
            return batteryService.percentage <= 15
                ? themeService.palette.warning : themeService.palette.accent
        }
        return themeService.palette.mutedText
    }

    IpcHandler {
        target: "pynix"

        function command(name: string): string {
            switch (name) {
            case "open-control-center":
                shell.controlCenterOpen = true
                break
            case "close-control-center":
                shell.controlCenterOpen = false
                break
            case "toggle-control-center":
                shell.controlCenterOpen = !shell.controlCenterOpen
                break
            case "expand-island":
                shell.islandExpanded = true
                break
            case "collapse-island":
                shell.islandExpanded = false
                break
            case "toggle-island":
                shell.islandExpanded = !shell.islandExpanded
                break
            case "open-settings":
                shell.settingsPage = "bar"
                shell.settingsOpen = true
                break
            case "open-theme-switcher":
                shell.settingsPage = "appearance"
                shell.settingsOpen = true
                break
            case "open-launcher":
                shell.launcherOpen = true
                break
            default:
                return "error: unsupported PyNix Shell command"
            }
            return "ok"
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: shell.currentTime = new Date()
    }

    Connections {
        target: settingsService
        function onThemeChanged() {
            themeService.applyTheme(settingsService.theme)
        }
    }

    Variants {
        variants: Quickshell.screens

        PanelWindow {
            id: panel
            property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            margins.top: settingsService.island.topOffset
            exclusiveZone: 0
            focusable: shell.controlCenterOpen
            color: "transparent"
            implicitHeight: shell.controlCenterOpen
                ? Math.max(570, settingsService.controlCenter.height + 80)
                : shell.islandExpanded ? settingsService.island.expandedHeight + 20 : settingsService.island.compactHeight + 18
            mask: Region {
                item: island
                Region {
                    item: shell.controlCenterOpen ? controlCenter : island
                }
            }

            Rectangle {
                id: island
                width: Math.max(0, Math.min(shell.islandExpanded
                    ? settingsService.island.expandedWidth : settingsService.island.compactWidth, parent.width - 24))
                height: shell.islandExpanded
                    ? settingsService.island.expandedHeight : settingsService.island.compactHeight
                x: (parent.width - width) / 2
                y: islandMouse.containsMouse && settingsService.island.hoverLift &&
                        !settingsService.motion.reducedMotion &&
                        !settingsService.motion.lowPerformance ? -3 : 0
                radius: shell.islandExpanded ? settingsService.island.radius : 999
                color: themeService.palette.surface
                border.width: 1
                border.color: themeService.palette.border
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: !settingsService.motion.animationsEnabled ||
                                settingsService.motion.reducedMotion ? 0 :
                                settingsService.motion.lowPerformance ? 100 : settingsService.motion.islandDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: !settingsService.motion.animationsEnabled ||
                                settingsService.motion.reducedMotion ? 0 :
                                settingsService.motion.lowPerformance ? 100 : settingsService.motion.islandDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: !settingsService.motion.animationsEnabled ||
                                settingsService.motion.reducedMotion ? 0 : settingsService.motion.panelDuration
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: !settingsService.motion.animationsEnabled ||
                                settingsService.motion.reducedMotion ||
                                settingsService.motion.lowPerformance ? 0 : 120
                    }
                }

                MouseArea {
                    id: islandMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: shell.islandExpanded = !shell.islandExpanded
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: settingsService.island.padding
                    anchors.rightMargin: settingsService.island.padding
                    spacing: settingsService.island.spacing
                    visible: !shell.islandExpanded

                    ColumnLayout {
                        spacing: 0
                        visible: settingsService.clock.showClock || settingsService.clock.showDate
                        Text {
                            text: settingsService.clock.showClock
                                ? Qt.formatTime(shell.currentTime, settingsService.clock.timeFormat) : ""
                            color: themeService.palette.primaryText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            text: settingsService.clock.showDate
                                ? Qt.formatDate(shell.currentTime, settingsService.clock.dateFormat) : ""
                            color: themeService.palette.secondaryText
                            font.pixelSize: 9
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 2
                        visible: settingsService.island.showStatusIndicators

                        Repeater {
                            model: settingsService.island.statusIndicatorOrder.filter(function(indicatorId) {
                                return settingsService.island.statusIndicatorVisibility[indicatorId]
                            })

                            delegate: Item {
                                required property string modelData
                                readonly property bool dataAvailable: shell.indicatorAvailable(modelData)
                                readonly property bool present: modelData !== "battery" || dataAvailable
                                width: 18
                                height: 18
                                opacity: present ? 1 : 0
                                Accessible.name: shell.indicatorDescription(modelData)
                                Accessible.ignored: !present

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    radius: width / 2
                                    color: themeService.palette.secondarySurface
                                    border.width: 1
                                    border.color: shell.indicatorColor(parent.modelData)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: shell.indicatorLabel(parent.modelData)
                                    color: shell.indicatorColor(parent.modelData)
                                    font.pixelSize: parent.modelData === "battery" ? 7 : 9
                                    font.bold: true
                                }

                                HoverHandler { id: indicatorHover }
                                ToolTip.visible: indicatorHover.hovered && present
                                ToolTip.text: shell.indicatorDescription(modelData)
                            }
                        }
                    }

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: mediaService.playing ? themeService.palette.accent : themeService.palette.mutedText
                        visible: settingsService.island.showStatusIndicators && mediaService.available
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: settingsService.island.padding
                    spacing: settingsService.island.spacing
                    visible: shell.islandExpanded

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: settingsService.island.spacing

                        Rectangle {
                            width: settingsService.island.showAlbumArt ? settingsService.island.albumArtSize : 0
                            height: width
                            radius: 14
                            color: themeService.palette.secondarySurface
                            clip: true
                            visible: settingsService.island.showAlbumArt

                            Image {
                                anchors.fill: parent
                                source: mediaService.artworkUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                visible: source !== ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: mediaService.title
                                color: themeService.palette.primaryText
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: mediaService.available ? mediaService.artist : "No MPRIS player available"
                                color: themeService.palette.secondaryText
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            ProgressBar {
                                Layout.fillWidth: true
                                from: 0
                                to: Math.max(mediaService.duration, 1)
                                value: mediaService.position
                                visible: mediaService.available && mediaService.duration > 0
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: settingsService.island.spacing * 2

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

            ControlCenter {
                id: controlCenter
                settings: settingsService
                themeService: themeService
                audioService: audioService
                mediaService: mediaService
                networkService: networkService
                bluetoothService: bluetoothService
                brightnessService: brightnessService
                notificationService: notificationService
                applicationService: applicationService
                visible: shell.controlCenterOpen
                opacity: visible ? 1 : 0
                onSettingsRequested: {
                    shell.settingsPage = "bar"
                    shell.settingsOpen = true
                }
                onLauncherRequested: shell.launcherOpen = true
                onCloseRequested: shell.controlCenterOpen = false
                Behavior on opacity {
                    NumberAnimation {
                        duration: !settingsService.motion.animationsEnabled ||
                                settingsService.motion.reducedMotion ? 0 :
                                settingsService.motion.lowPerformance ? 90 : settingsService.motion.panelDuration
                    }
                }
            }

            ToolButton {
                width: 40
                height: 40
                x: parent.width - width - 20
                y: 8
                text: "⋯"
                Accessible.name: "Open Control Center"
                onClicked: shell.controlCenterOpen = !shell.controlCenterOpen
                contentItem: Text {
                    text: parent.text
                    color: themeService.palette.primaryText
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 14
                    color: themeService.palette.surface
                    border.width: parent.activeFocus ? 2 : 1
                    border.color: parent.activeFocus
                        ? themeService.palette.accent : themeService.palette.border
                }
            }
        }
    }

    Variants {
        variants: Quickshell.screens

        SettingsWindow {
            settings: settingsService
            themeService: themeService
            audioService: audioService
            mediaService: mediaService
            networkService: networkService
            bluetoothService: bluetoothService
            brightnessService: brightnessService
            applicationService: applicationService
            notificationService: notificationService
            initialPage: shell.settingsPage
            opened: shell.settingsOpen
            onCloseRequested: shell.settingsOpen = false
        }
    }

    LauncherWindow {
        settings: settingsService
        themeService: themeService
        applicationService: applicationService
        opened: shell.launcherOpen
    }
}

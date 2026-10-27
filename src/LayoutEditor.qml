import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: editor

    required property var settings
    required property var palette
    required property var audioService
    required property var mediaService
    required property var networkService
    required property var bluetoothService
    required property var brightnessService
    required property var notificationService

    spacing: 12

    function tileName(id) {
        var names = {
            audio: "Output audio",
            media: "MPRIS media",
            appearance: "Theme",
            motion: "Motion preferences",
            wifi: "Wi-Fi",
            bluetooth: "Bluetooth",
            brightness: "Display brightness",
            notifications: "Notifications"
        }
        return names[id] || id
    }

    function tileEnabled(id) {
        return editor.settings.currentTiles().some(function(tile) { return tile.id === id })
    }

    function tileSummary(tile) {
        switch (tile.id) {
        case "audio":
            return audioService.available
                ? (audioService.muted ? "Muted" : Math.round(audioService.volume * 100) + "% output volume")
                : "PipeWire output unavailable"
        case "media":
            return mediaService.available
                ? mediaService.title + " — " + mediaService.artist
                : "No MPRIS player"
        case "appearance":
            return "Current theme: " + settings.theme
        case "motion":
            return settings.motion.reducedMotion ? "Reduced motion enabled"
                : settings.motion.lowPerformance ? "Low-performance mode enabled"
                    : "Standard transitions"
        case "wifi":
            return networkService.connected
                ? "Connected to " + networkService.ssid
                : networkService.status
        case "bluetooth":
            return bluetoothService.connectedDeviceCount > 0
                ? bluetoothService.connectedDeviceCount + " connected device(s)"
                : bluetoothService.status
        case "brightness":
            return brightnessService.available
                ? Math.round(brightnessService.value * 100) + "% hardware brightness"
                : brightnessService.status
        case "notifications":
            return notificationService.count + " active notification(s)"
        default:
            return "Unavailable"
        }
    }

    RowLayout {
        Layout.fillWidth: true

        ComboBox {
            id: presetSelector
            Layout.fillWidth: true
            model: ["Balanced", "Compact", "Media-focused", "Custom"]
            currentIndex: Math.max(0, model.indexOf(editor.settings.controlCenter.preset))
            onActivated: {
                if (currentText !== "Custom")
                    editor.settings.applyPreset(currentText)
            }
        }
        Button {
            text: "Tidy"
            onClicked: editor.settings.tidyLayout()
        }
        Button {
            text: "Undo"
            enabled: editor.settings.layoutHistory.length > 0
            onClicked: editor.settings.undoLayout()
        }
        Button {
            text: "Reset"
            onClicked: editor.settings.resetLayout()
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Drag tiles to swap grid positions. Compact tiles use one column; normal and large tiles span both. Right-click a tile for resize and move options, or use its keyboard move buttons."
        color: editor.palette.secondaryText
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            Layout.fillWidth: true
            text: "Enabled tiles"
            color: editor.palette.primaryText
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Repeater {
            model: editor.settings.supportedTiles
            delegate: CheckBox {
                required property string modelData
                Layout.fillWidth: true
                text: editor.tileName(modelData)
                checked: editor.tileEnabled(modelData)
                onToggled: editor.settings.setTileEnabled(modelData, checked)
                Accessible.name: "Show " + editor.tileName(modelData) + " tile"
            }
        }
    }

    GridLayout {
        id: preview
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: editor.settings.currentTiles()

            delegate: Item {
                id: tileItem
                required property int index
                required property var modelData
                Layout.fillWidth: true
                Layout.row: tileItem.modelData.gridRow
                Layout.column: tileItem.modelData.gridColumn
                Layout.columnSpan: tileItem.modelData.size === "compact" ? 1 : 2
                implicitHeight: editor.settings.tileHeight(tileItem.modelData.size, tileItem.modelData.id)
                z: card.Drag.active ? 2 : 0

                DropArea {
                    z: 1
                    anchors.fill: parent
                    keys: ["pynix-control-center-layout"]
                    onDropped: function(drop) {
                        if (drop.source && drop.source.startIndex !== undefined) {
                            editor.settings.moveTile(drop.source.startIndex, tileItem.index)
                            drop.acceptProposedAction()
                        }
                    }
                }

                Rectangle {
                    id: card
                    property int tileIndex: tileItem.index
                    property int startIndex: tileItem.index
                    property bool dragActive: false
                    width: parent.width
                    height: parent.height
                    radius: 14
                    color: card.dragActive ? editor.palette.hover : editor.palette.secondarySurface
                    border.width: 1
                    border.color: card.dragActive ? editor.palette.accent : editor.palette.border
                    Drag.active: grip.drag.active
                    Drag.source: card
                    Drag.keys: ["pynix-control-center-layout"]
                    Drag.hotSpot.x: 22
                    Drag.hotSpot.y: height / 2

                    Menu {
                        id: tileMenu
                        title: editor.tileName(tileItem.modelData.id)
                        MenuItem {
                            text: "Resize to compact"
                            onTriggered: editor.settings.resizeTile(tileItem.index, "compact")
                        }
                        MenuItem {
                            text: "Resize to normal"
                            onTriggered: editor.settings.resizeTile(tileItem.index, "normal")
                        }
                        MenuItem {
                            text: "Resize to large"
                            onTriggered: editor.settings.resizeTile(tileItem.index, "large")
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "Set grid position..."
                            onTriggered: {
                                positionDialog.tileIndex = tileItem.index
                                positionDialog.tileSize = tileItem.modelData.size
                                targetRow.value = tileItem.modelData.gridRow + 1
                                targetColumn.currentIndex = tileItem.modelData.gridColumn
                                positionDialog.open()
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "Move left"
                            enabled: tileItem.modelData.gridColumn > 0
                            onTriggered: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn - 1,
                                tileItem.modelData.gridRow)
                        }
                        MenuItem {
                            text: "Move right"
                            enabled: tileItem.modelData.size === "compact" &&
                                tileItem.modelData.gridColumn < 1
                            onTriggered: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn + 1,
                                tileItem.modelData.gridRow)
                        }
                        MenuItem {
                            text: "Move up"
                            enabled: tileItem.modelData.gridRow > 0
                            onTriggered: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn,
                                tileItem.modelData.gridRow - 1)
                        }
                        MenuItem {
                            text: "Move down"
                            enabled: tileItem.modelData.gridRow < 20
                            onTriggered: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn,
                                tileItem.modelData.gridRow + 1)
                        }
                    }

                    Dialog {
                        id: positionDialog
                        property int tileIndex: -1
                        property string tileSize: "normal"
                        title: "Set tile grid position"
                        modal: true
                        standardButtons: Dialog.Ok | Dialog.Cancel
                        onAccepted: editor.settings.moveTileTo(
                            tileIndex,
                            tileSize === "compact" ? targetColumn.currentIndex : 0,
                            targetRow.value - 1)

                        ColumnLayout {
                            anchors.fill: parent
                            Label {
                                text: "Row (1–21)"
                            }
                            SpinBox {
                                id: targetRow
                                from: 1
                                to: 21
                                value: 1
                                Accessible.name: "Tile grid row"
                            }
                            Label {
                                text: "Column"
                            }
                            ComboBox {
                                id: targetColumn
                                model: ["Column 1", "Column 2"]
                                Accessible.name: "Tile grid column"
                                enabled: positionDialog.tileSize === "compact"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: tileMenu.popup()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 8

                        MouseArea {
                            id: grip
                            Layout.preferredWidth: 34
                            Layout.fillHeight: true
                            cursorShape: Qt.PointingHandCursor
                            drag.target: card
                            onPressed: {
                                card.startIndex = tileItem.index
                                card.dragActive = true
                            }
                            onReleased: card.dragActive = false
                            Text {
                                anchors.centerIn: parent
                                text: "☰"
                                color: editor.palette.mutedText
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: editor.tileName(tileItem.modelData.id)
                                color: editor.palette.primaryText
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: editor.tileSummary(tileItem.modelData)
                                color: editor.palette.secondaryText
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        ComboBox {
                            Layout.preferredWidth: 112
                            model: ["compact", "normal", "large"]
                            currentIndex: Math.max(0, model.indexOf(tileItem.modelData.size))
                            onActivated: editor.settings.resizeTile(tileItem.index, currentText)
                        }

                        ToolButton {
                            text: "←"
                            Accessible.name: "Move " + editor.tileName(tileItem.modelData.id) + " left"
                            enabled: tileItem.modelData.gridColumn > 0
                            onClicked: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn - 1,
                                tileItem.modelData.gridRow)
                        }
                        ToolButton {
                            text: "→"
                            Accessible.name: "Move " + editor.tileName(tileItem.modelData.id) + " right"
                            enabled: tileItem.modelData.size === "compact" &&
                                tileItem.modelData.gridColumn < 1
                            onClicked: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn + 1,
                                tileItem.modelData.gridRow)
                        }
                        ToolButton {
                            text: "↑"
                            Accessible.name: "Move " + editor.tileName(tileItem.modelData.id) + " up"
                            enabled: tileItem.modelData.gridRow > 0
                            onClicked: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn,
                                tileItem.modelData.gridRow - 1)
                        }
                        ToolButton {
                            text: "↓"
                            Accessible.name: "Move " + editor.tileName(tileItem.modelData.id) + " down"
                            enabled: tileItem.modelData.gridRow < 20
                            onClicked: editor.settings.moveTileTo(
                                tileItem.index,
                                tileItem.modelData.gridColumn,
                                tileItem.modelData.gridRow + 1)
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: editor.settings.layoutMessage
        color: editor.palette.error
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        visible: text.length > 0
        Accessible.live: Accessible.Polite
    }

    Text {
        Layout.fillWidth: true
        text: "NetworkManager, BlueZ, and backlight controls report unavailable hardware or services instead of simulating state. Notifications remain unimplemented."
        color: editor.palette.mutedText
        font.pixelSize: 10
        wrapMode: Text.WordWrap
    }
}

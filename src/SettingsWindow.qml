import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: window

    property var modelData
    required property var settings
    required property var themeService
    required property var audioService
    required property var mediaService
    required property var networkService
    required property var bluetoothService
    required property var brightnessService
    required property var applicationService
    required property var notificationService
    property bool opened: false
    property bool closing: false
    property string initialPage: "bar"
    readonly property int transitionDuration: !settings.motion.animationsEnabled ||
            settings.motion.reducedMotion ? 0 :
            settings.motion.lowPerformance ? 80 : settings.motion.panelDuration
    signal closeRequested()

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    focusable: true
    visible: opened || closing
    color: "transparent"
    mask: Region { item: surface }

    Timer {
        id: closeTimer
        interval: window.transitionDuration
        onTriggered: window.closing = false
    }

    readonly property var pages: [
        { id: "bar", title: "Bar & Island", keywords: "island capsule bar compact expanded width height radius offset padding spacing indicators album art size hover" },
        { id: "clock", title: "Clock & Date", keywords: "clock time date format 12 24 hour" },
        { id: "appearance", title: "Appearance", keywords: "appearance theme color palette material nightfox noir desert ocean rose" },
        { id: "motion", title: "Motion", keywords: "motion animation reduced low performance transition duration" },
        { id: "launcher", title: "Launcher", keywords: "launcher application desktop entry search results width" },
        { id: "notifications", title: "Notifications", keywords: "notifications history maximum visible" },
        { id: "control-center", title: "Control Center", keywords: "control center layout editor tiles preset tidy undo reset resize audio volume media brightness bluetooth wifi" },
        { id: "lock-screen", title: "Lock Screen", keywords: "lock screen hyprlock security" },
        { id: "system", title: "System", keywords: "system version configuration integration status diagnostics" }
    ]
    property string activePage: "bar"
    property string searchText: ""

    function pageTitle(id) {
        for (var index = 0; index < pages.length; index++) {
            if (pages[index].id === id)
                return pages[index].title
        }
        return "Settings"
    }

    function filteredPages() {
        var query = searchText.trim().toLowerCase()
        if (!query)
            return pages
        return pages.filter(function(page) {
            return (page.title + " " + page.keywords).toLowerCase().indexOf(query) >= 0
        })
    }

    function indicatorIndex(indicatorId) {
        return settings.island.statusIndicatorOrder.indexOf(indicatorId)
    }

    function moveIndicator(indicatorId, offset) {
        settings.moveStatusIndicator(indicatorId, offset)
    }

    onOpenedChanged: {
        if (opened) {
            closing = false
            activePage = pageTitle(initialPage) === "Settings" ? "bar" : initialPage
            searchText = ""
            searchField.forceActiveFocus()
        } else {
            closing = true
            closeTimer.restart()
        }
    }
    onInitialPageChanged: {
        if (opened) {
            activePage = pageTitle(initialPage) === "Settings" ? "bar" : initialPage
            searchText = ""
        }
    }

    Keys.onEscapePressed: function(event) {
        event.accepted = true
        closeRequested()
    }

    Rectangle {
        id: surface
        width: Math.min(1100, Math.max(320, window.screen.width - 40))
        height: Math.min(760, Math.max(320, window.screen.height - 40))
        anchors.centerIn: parent
        radius: 24
        color: themeService.palette.background
        border.width: 1
        border.color: themeService.palette.border
        clip: true
        opacity: window.opened ? 1 : 0
        scale: window.opened ? 1 : 0.98

        Behavior on opacity {
            NumberAnimation {
                duration: window.transitionDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: window.transitionDuration
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                Layout.preferredWidth: Math.min(250, surface.width * 0.27)
                Layout.fillHeight: true
                radius: 18
                color: themeService.palette.surface

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label {
                            text: "PyNix Shell"
                            color: themeService.palette.primaryText
                            font.pixelSize: 17
                            font.bold: true
                        }
                        Label {
                            text: "Settings"
                            color: themeService.palette.secondaryText
                            font.pixelSize: 11
                        }
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search settings"
                        Accessible.name: "Search settings"
                        selectByMouse: true
                        Keys.onEscapePressed: function(event) {
                            event.accepted = true
                            window.closeRequested()
                        }
                        onTextChanged: {
                            window.searchText = text
                            var matching = window.filteredPages()
                            if (matching.length > 0 &&
                                    !matching.some(function(page) { return page.id === window.activePage; }))
                                window.activePage = matching[0].id
                        }
                        background: Rectangle {
                            radius: 10
                            color: themeService.palette.secondarySurface
                            border.width: searchField.activeFocus ? 2 : 1
                            border.color: searchField.activeFocus
                                ? themeService.palette.accent : themeService.palette.border
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width
                            anchors.top: parent.top
                            spacing: 4

                            Repeater {
                                model: window.filteredPages()
                                delegate: Button {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    checkable: true
                                    checked: window.activePage === modelData.id
                                    onClicked: window.activePage = modelData.id
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.checked
                                            ? themeService.palette.primaryText : themeService.palette.secondaryText
                                        font.pixelSize: 12
                                        font.weight: parent.checked ? Font.DemiBold : Font.Normal
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                    }
                                    background: Rectangle {
                                        radius: 10
                                        color: parent.checked
                                            ? themeService.palette.selected : parent.hovered
                                                ? themeService.palette.hover : "transparent"
                                        border.width: parent.activeFocus ? 2 : 0
                                        border.color: themeService.palette.accent
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: window.filteredPages().length === 0
                                text: "No matching settings"
                                color: themeService.palette.mutedText
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Changes save to your user settings."
                        color: themeService.palette.mutedText
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: themeService.palette.surface
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: window.pageTitle(window.activePage)
                            color: themeService.palette.primaryText
                            font.pixelSize: 22
                            font.bold: true
                        }
                        ToolButton {
                            text: "×"
                            Accessible.name: "Close Settings"
                            onClicked: window.closeRequested()
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Loader {
                            id: pageLoader
                            width: parent.width
                            sourceComponent: {
                                switch (window.activePage) {
                                case "bar": return barPage
                                case "clock": return clockPage
                                case "appearance": return appearancePage
                                case "motion": return motionPage
                                case "launcher": return launcherPage
                                case "notifications": return notificationsPage
                                case "control-center": return controlCenterPage
                                case "lock-screen": return lockScreenPage
                                case "system": return systemPage
                                default: return barPage
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: barPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: "Adjust the island's real dimensions and content."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            SettingsRow {
                title: "Compact width"
                description: "Capsule width in logical pixels."
                palette: themeService.palette
                SpinBox { from: 140; to: 500; value: settings.island.compactWidth; onValueModified: settings.island.compactWidth = value }
            }
            SettingsRow {
                title: "Compact height"
                description: "Capsule height in logical pixels."
                palette: themeService.palette
                SpinBox { from: 36; to: 100; value: settings.island.compactHeight; onValueModified: settings.island.compactHeight = value }
            }
            SettingsRow {
                title: "Expanded width"
                description: "Maximum width of the media island."
                palette: themeService.palette
                SpinBox { from: 280; to: 760; value: settings.island.expandedWidth; onValueModified: settings.island.expandedWidth = value }
            }
            SettingsRow {
                title: "Expanded height"
                description: "Expanded media panel height."
                palette: themeService.palette
                SpinBox { from: 140; to: 420; value: settings.island.expandedHeight; onValueModified: settings.island.expandedHeight = value }
            }
            SettingsRow {
                title: "Corner radius"
                description: "Rounded corner radius for the expanded island."
                palette: themeService.palette
                Slider {
                    Layout.preferredWidth: 150
                    from: 12; to: 80; stepSize: 1
                    value: settings.island.radius
                    Accessible.name: "Expanded island corner radius"
                    onMoved: settings.island.radius = Math.round(value)
                    Keys.onLeftPressed: function(event) {
                        event.accepted = true
                        settings.island.radius = Math.max(12, settings.island.radius - 1)
                    }
                    Keys.onDownPressed: function(event) {
                        event.accepted = true
                        settings.island.radius = Math.max(12, settings.island.radius - 1)
                    }
                    Keys.onRightPressed: function(event) {
                        event.accepted = true
                        settings.island.radius = Math.min(80, settings.island.radius + 1)
                    }
                    Keys.onUpPressed: function(event) {
                        event.accepted = true
                        settings.island.radius = Math.min(80, settings.island.radius + 1)
                    }
                }
                Label { text: settings.island.radius + " px"; color: themeService.palette.secondaryText }
            }
            SettingsRow {
                title: "Top offset"
                description: "Distance from the top edge of the screen."
                palette: themeService.palette
                SpinBox { from: 0; to: 80; value: settings.island.topOffset; onValueModified: settings.island.topOffset = value }
            }
            SettingsRow {
                title: "Padding and spacing"
                description: "Content inset and space between island items."
                palette: themeService.palette
                SpinBox { from: 6; to: 36; value: settings.island.padding; onValueModified: settings.island.padding = value }
                SpinBox { from: 4; to: 28; value: settings.island.spacing; onValueModified: settings.island.spacing = value }
            }
            SettingsRow {
                title: "Status indicators"
                description: "Show relevant system indicators in the compact capsule."
                palette: themeService.palette
                Switch {
                    checked: settings.island.showStatusIndicators
                    onToggled: settings.island.showStatusIndicators = checked
                    Accessible.name: "Show status indicators"
                }
            }
            Repeater {
                model: [
                    { id: "network", title: "Wi-Fi indicator", description: "Shows connected, disconnected, disabled, unavailable, or failed state." },
                    { id: "bluetooth", title: "Bluetooth indicator", description: "Shows adapter availability and whether a device is connected." },
                    { id: "audio", title: "Audio indicator", description: "Shows output availability and mute state." },
                    { id: "battery", title: "Battery indicator", description: "Shown only when UPower exposes a present system battery." }
                ]
                delegate: SettingsRow {
                    required property var modelData
                    title: modelData.title
                    description: modelData.description
                    palette: themeService.palette
                    Switch {
                        checked: settings.island.statusIndicatorVisibility[modelData.id]
                        enabled: settings.island.showStatusIndicators
                        onToggled: settings.island.statusIndicatorVisibility[modelData.id] = checked
                        Accessible.name: "Show " + modelData.id + " status indicator"
                    }
                    ToolButton {
                        text: "↑"
                        enabled: settings.island.showStatusIndicators &&
                            window.indicatorIndex(modelData.id) > 0
                        Accessible.name: "Move " + modelData.id + " indicator earlier"
                        onClicked: window.moveIndicator(modelData.id, -1)
                    }
                    ToolButton {
                        text: "↓"
                        enabled: settings.island.showStatusIndicators &&
                            window.indicatorIndex(modelData.id) < settings.island.statusIndicatorOrder.length - 1
                        Accessible.name: "Move " + modelData.id + " indicator later"
                        onClicked: window.moveIndicator(modelData.id, 1)
                    }
                }
            }
            SettingsRow {
                title: "Album artwork"
                description: "Show the active player's provided artwork when available."
                palette: themeService.palette
                Switch {
                    checked: settings.island.showAlbumArt
                    onToggled: settings.island.showAlbumArt = checked
                    Accessible.name: "Show album artwork"
                }
                SpinBox {
                    from: 40; to: 120
                    value: settings.island.albumArtSize
                    enabled: settings.island.showAlbumArt
                    onValueModified: settings.island.albumArtSize = value
                }
            }
            SettingsRow {
                title: "Hover lift"
                description: "Raise the island slightly while the pointer is over it."
                palette: themeService.palette
                Switch {
                    checked: settings.island.hoverLift
                    onToggled: settings.island.hoverLift = checked
                    Accessible.name: "Enable island hover lift"
                }
            }
        }
    }

    Component {
        id: clockPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: "Choose how time and date are shown in the island."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            SettingsRow {
                title: "Show clock"
                description: "Display the live system clock in the compact island."
                palette: themeService.palette
                Switch {
                    checked: settings.clock.showClock
                    onToggled: settings.clock.showClock = checked
                    Accessible.name: "Show clock"
                }
            }
            SettingsRow {
                title: "Time format"
                description: "Use 24-hour or 12-hour time."
                palette: themeService.palette
                ComboBox {
                    model: ["24-hour", "12-hour"]
                    currentIndex: settings.clock.timeFormat === "hh:mm AP" ? 1 : 0
                    onActivated: settings.clock.timeFormat = currentIndex === 1 ? "hh:mm AP" : "HH:mm"
                }
            }
            SettingsRow {
                title: "Show date"
                description: "Show today's date beside the clock when space permits."
                palette: themeService.palette
                Switch {
                    checked: settings.clock.showDate
                    onToggled: settings.clock.showDate = checked
                    Accessible.name: "Show date"
                }
            }
            SettingsRow {
                title: "Date format"
                description: "Select a concise or full date representation."
                palette: themeService.palette
                ComboBox {
                    model: ["ddd, d MMM", "yyyy-MM-dd", "dddd, d MMMM"]
                    currentIndex: Math.max(0, model.indexOf(settings.clock.dateFormat))
                    onActivated: settings.clock.dateFormat = currentText
                }
            }
        }
    }

    Component {
        id: appearancePage
        ColumnLayout {
            width: pageLoader.width
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: "Themes update shared palette tokens used by the island and Control Center."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            SettingsRow {
                title: "Built-in theme"
                description: "Choose a built-in PyNix palette."
                palette: themeService.palette
                ComboBox {
                    model: ["material-you", "nightfox", "noir", "desert", "ocean", "rose"]
                    currentIndex: Math.max(0, model.indexOf(settings.theme))
                    onActivated: settings.theme = currentText
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 116
                radius: 16
                color: themeService.palette.secondarySurface
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10
                    Repeater {
                        model: [
                            themeService.palette.background,
                            themeService.palette.surface,
                            themeService.palette.accent,
                            themeService.palette.selected
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            color: modelData
                            border.width: 1
                            border.color: themeService.palette.border
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                text: "Accent and surface colors are currently defined by the selected built-in palette; custom color editing is not implemented."
                color: themeService.palette.mutedText
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: motionPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 8
            SettingsRow {
                title: "Animations"
                description: "Enable island and panel transitions."
                palette: themeService.palette
                Switch {
                    checked: settings.motion.animationsEnabled
                    onToggled: settings.motion.animationsEnabled = checked
                    Accessible.name: "Enable animations"
                }
            }
            SettingsRow {
                title: "Reduced motion"
                description: "Disable nonessential animated transitions."
                palette: themeService.palette
                Switch {
                    checked: settings.motion.reducedMotion
                    onToggled: settings.motion.reducedMotion = checked
                    Accessible.name: "Enable reduced motion"
                }
            }
            SettingsRow {
                title: "Low-performance mode"
                description: "Use shorter transitions and avoid optional motion."
                palette: themeService.palette
                Switch {
                    checked: settings.motion.lowPerformance
                    onToggled: settings.motion.lowPerformance = checked
                    Accessible.name: "Enable low-performance mode"
                }
            }
            SettingsRow {
                title: "Island transition"
                description: "Duration of island geometry changes."
                palette: themeService.palette
                SpinBox {
                    from: 0; to: 600; stepSize: 20
                    value: settings.motion.islandDuration
                    enabled: settings.motion.animationsEnabled && !settings.motion.reducedMotion
                    onValueModified: settings.motion.islandDuration = value
                }
            }
            SettingsRow {
                title: "Panel transition"
                description: "Duration of Control Center fades."
                palette: themeService.palette
                SpinBox {
                    from: 0; to: 600; stepSize: 20
                    value: settings.motion.panelDuration
                    enabled: settings.motion.animationsEnabled && !settings.motion.reducedMotion
                    onValueModified: settings.motion.panelDuration = value
                }
            }
            SettingsRow {
                title: "Island hover lift"
                description: "This uses the Bar & Island page's hover setting."
                palette: themeService.palette
                Switch {
                    checked: settings.island.hoverLift
                    onToggled: settings.island.hoverLift = checked
                    Accessible.name: "Enable island hover lift"
                }
            }
        }
    }

    Component {
        id: launcherPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 12
            Label {
                Layout.fillWidth: true
                text: "Search installed desktop applications and launch them from the Control Center."
                color: themeService.palette.primaryText
                font.pixelSize: 15
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: applicationService.launcherAvailable
                    ? applicationService.applications.length + " desktop entries found; launch support is ready."
                    : applicationService.errorMessage ||
                        "Checking desktop entries and gtk-launch availability."
                color: applicationService.launcherAvailable
                    ? themeService.palette.success : themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            SettingsRow {
                Layout.fillWidth: true
                title: "Launcher width"
                description: "Width of the application search window."
                palette: themeService.palette
                Slider {
                    from: 320
                    to: 900
                    value: settings.launcher.width
                    onMoved: settings.launcher.width = Math.round(value)
                    Accessible.name: "Launcher window width"
                }
                Label {
                    text: settings.launcher.width + " px"
                    color: themeService.palette.secondaryText
                }
            }
            SettingsRow {
                Layout.fillWidth: true
                title: "Maximum results"
                description: "Limit visible matches for a compact launcher."
                palette: themeService.palette
                Slider {
                    from: 3
                    to: 20
                    stepSize: 1
                    value: settings.launcher.maxResults
                    onMoved: settings.launcher.maxResults = Math.round(value)
                    Accessible.name: "Maximum launcher results"
                }
                Label {
                    text: settings.launcher.maxResults.toString()
                    color: themeService.palette.secondaryText
                }
            }
        }
    }

    Component {
        id: notificationsPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 12
            Label {
                Layout.fillWidth: true
                text: "Quickshell provides the session's Freedesktop notification server."
                color: themeService.palette.primaryText
                font.pixelSize: 15
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: "Active notifications: " + notificationService.count +
                    ". If another daemon already owns the desktop notification service, delivery may conflict."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            SettingsRow {
                Layout.fillWidth: true
                title: "Visible notification limit"
                description: "Maximum active notifications shown in Control Center."
                palette: themeService.palette
                Slider {
                    from: 1
                    to: 20
                    stepSize: 1
                    value: settings.notifications.maxVisible
                    onMoved: settings.notifications.maxVisible = Math.round(value)
                    Accessible.name: "Visible notification limit"
                }
                Label {
                    text: settings.notifications.maxVisible.toString()
                    color: themeService.palette.secondaryText
                }
            }
            Button {
                text: "Dismiss all active notifications"
                enabled: notificationService.count > 0
                onClicked: notificationService.clearAll()
            }
        }
    }

    Component {
        id: controlCenterPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 14
            Label {
                Layout.fillWidth: true
                text: "The editor changes the same tile order and sizes used by the live Control Center."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
            LayoutEditor {
                Layout.fillWidth: true
                settings: window.settings
                palette: themeService.palette
                audioService: window.audioService
                mediaService: window.mediaService
                networkService: window.networkService
                bluetoothService: window.bluetoothService
                brightnessService: window.brightnessService
                notificationService: window.notificationService
            }
            SettingsRow {
                title: "Panel width"
                description: "Maximum width of the floating panel."
                palette: themeService.palette
                SpinBox {
                    from: 320; to: 720
                    value: settings.controlCenter.width
                    onValueModified: settings.controlCenter.width = value
                }
            }
            SettingsRow {
                title: "Panel height"
                description: "Maximum height before its contents scroll."
                palette: themeService.palette
                SpinBox {
                    from: 320; to: 900
                    value: settings.controlCenter.height
                    onValueModified: settings.controlCenter.height = value
                }
            }
            SettingsRow {
                title: "Panel corner radius"
                description: "Rounded panel corners."
                palette: themeService.palette
                SpinBox {
                    from: 8; to: 48
                    value: settings.controlCenter.radius
                    onValueModified: settings.controlCenter.radius = value
                }
            }
        }
    }

    Component {
        id: lockScreenPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 10
            Label {
                Layout.fillWidth: true
                text: "PyNix Shell does not provide a lock screen."
                color: themeService.palette.primaryText
                font.pixelSize: 15
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                text: "No host lock-screen configuration is inspected or changed. Continue using your existing trusted lock-screen tool, such as hyprlock if it is already configured. No password or security controls are exposed here."
                color: themeService.palette.secondaryText
                wrapMode: Text.WordWrap
            }
        }
    }

    Component {
        id: systemPage
        ColumnLayout {
            width: pageLoader.width
            spacing: 8
            SettingsRow {
                title: "PyNix Shell"
                description: "Project version metadata is not declared in this development build."
                palette: themeService.palette
                Label { text: "Development build"; color: themeService.palette.secondaryText }
            }
            SettingsRow {
                title: "Quickshell"
                description: "The QML API does not expose a verified runtime version here."
                palette: themeService.palette
                Label { text: "Version unavailable"; color: themeService.palette.secondaryText }
            }
            SettingsRow {
                title: "Active theme"
                description: "Shared palette applied to shell surfaces."
                palette: themeService.palette
                Label { text: themeService.activeTheme; color: themeService.palette.accent }
            }
            SettingsRow {
                title: "Settings file"
                description: "User-owned structured preferences."
                palette: themeService.palette
                Label {
                    Layout.maximumWidth: 260
                    text: settings.storagePath || "Unavailable: no absolute XDG_CONFIG_HOME or HOME"
                    color: themeService.palette.secondaryText
                    wrapMode: Text.WrapAnywhere
                }
            }
            SettingsRow {
                title: "MPRIS media"
                description: "Quickshell media-player service."
                palette: themeService.palette
                Label {
                    text: mediaService.available ? "Available" : "No player"
                    color: mediaService.available ? themeService.palette.success : themeService.palette.mutedText
                }
            }
            SettingsRow {
                title: "PipeWire output"
                description: "Default audio sink."
                palette: themeService.palette
                Label {
                    text: audioService.available ? "Available" : "Unavailable"
                    color: audioService.available ? themeService.palette.success : themeService.palette.mutedText
                }
            }
            SettingsRow {
                title: "NetworkManager Wi-Fi"
                description: "Live NetworkManager state and connection support."
                palette: themeService.palette
                Label {
                    text: networkService.connected
                        ? networkService.status + " (" + networkService.ssid + ")"
                        : networkService.failureMessage || networkService.status
                    color: networkService.failureMessage
                        ? themeService.palette.error
                        : !networkService.available ? themeService.palette.mutedText
                            : networkService.connected ? themeService.palette.success
                                : themeService.palette.secondaryText
                    elide: Text.ElideRight
                }
            }
            SettingsRow {
                title: "BlueZ Bluetooth"
                description: "Adapter state and connected-device availability."
                palette: themeService.palette
                Label {
                    text: bluetoothService.failureMessage || bluetoothService.status
                    color: bluetoothService.failureMessage
                        ? themeService.palette.error
                        : !bluetoothService.available ? themeService.palette.mutedText
                            : bluetoothService.enabled ? themeService.palette.success
                                : themeService.palette.secondaryText
                }
            }
            SettingsRow {
                title: "Backlight"
                description: "Optional brightnessctl backlight interface."
                palette: themeService.palette
                Label {
                    text: brightnessService.failureMessage ||
                            (brightnessService.available
                                ? Math.round(brightnessService.value * 100) + "% — " + brightnessService.status
                                : brightnessService.status)
                    color: brightnessService.failureMessage
                        ? themeService.palette.error
                        : brightnessService.available ? themeService.palette.success : themeService.palette.mutedText
                    elide: Text.ElideRight
                }
            }
            SettingsRow {
                title: "Other integrations"
                description: "Notification server, launcher, and lock-screen integration."
                palette: themeService.palette
                Label { text: "Not implemented"; color: themeService.palette.mutedText }
            }
        }
    }
}

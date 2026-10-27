import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: settingsService

    readonly property string configRoot: {
        var configuredRoot = Quickshell.env("XDG_CONFIG_HOME")
        if (configuredRoot && configuredRoot.startsWith("/"))
            return configuredRoot
        var home = Quickshell.env("HOME")
        return home && home.startsWith("/") ? home + "/.config" : ""
    }
    readonly property string storagePath: configRoot ? configRoot + "/pynix-shell/settings.json" : ""
    readonly property var supportedTiles: [
        "audio", "media", "appearance", "motion", "wifi", "bluetooth", "brightness",
        "notifications"
    ]

    property alias theme: preferences.theme
    property alias island: preferences.island
    property alias clock: preferences.clock
    property alias motion: preferences.motion
    property alias launcher: preferences.launcher
    property alias notifications: preferences.notifications
    property alias controlCenter: preferences.controlCenter
    property bool persistable: false
    property var layoutHistory: []
    property string layoutMessage: ""

    FileView {
        path: settingsService.storagePath
        atomicWrites: true

        onLoaded: {
            settingsService.persistable = true
            settingsService.normalizePreferences()
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                settingsService.persistable = true
                settingsService.normalizePreferences()
                return
            }
            console.warn("SettingsService: could not load user settings; retaining defaults:",
                         FileViewError.toString(error))
            settingsService.persistable = false
        }
        onAdapterUpdated: {
            if (settingsService.persistable)
                writeAdapter()
        }
        onSaveFailed: function(error) {
            console.warn("SettingsService: failed to save user settings:", FileViewError.toString(error))
        }

        JsonAdapter {
            id: preferences
            property string theme: "material-you"
            property JsonObject island: JsonObject {
                property int compactWidth: 208
                property int compactHeight: 50
                property int expandedWidth: 390
                property int expandedHeight: 204
                property int topOffset: 8
                property int radius: 26
                property int padding: 16
                property int spacing: 12
                property bool showStatusIndicators: true
                property var statusIndicatorOrder: ["network", "bluetooth", "audio", "battery"]
                property JsonObject statusIndicatorVisibility: JsonObject {
                    property bool network: true
                    property bool bluetooth: true
                    property bool audio: true
                    property bool battery: true
                }
                property bool showAlbumArt: true
                property int albumArtSize: 64
                property bool hoverLift: true
            }
            property JsonObject clock: JsonObject {
                property bool showClock: true
                property string timeFormat: "HH:mm"
                property bool showDate: false
                property string dateFormat: "ddd, d MMM"
            }
            property JsonObject motion: JsonObject {
                property bool animationsEnabled: true
                property bool reducedMotion: false
                property bool lowPerformance: false
                property int islandDuration: 220
                property int panelDuration: 180
            }
            property JsonObject launcher: JsonObject {
                property int width: 540
                property int maxResults: 7
            }
            property JsonObject notifications: JsonObject {
                property int maxVisible: 5
            }
            property JsonObject controlCenter: JsonObject {
                property int width: 420
                property int height: 520
                property int radius: 28
                property string preset: "Balanced"
                property var tiles: [
                    { "id": "audio", "size": "normal", "gridColumn": 0, "gridRow": 0 },
                    { "id": "media", "size": "normal", "gridColumn": 0, "gridRow": 1 },
                    { "id": "appearance", "size": "normal", "gridColumn": 0, "gridRow": 2 },
                    { "id": "motion", "size": "normal", "gridColumn": 0, "gridRow": 3 },
                    { "id": "wifi", "size": "normal", "gridColumn": 0, "gridRow": 4 },
                    { "id": "bluetooth", "size": "normal", "gridColumn": 0, "gridRow": 5 },
                    { "id": "brightness", "size": "normal", "gridColumn": 0, "gridRow": 6 },
                    { "id": "notifications", "size": "normal", "gridColumn": 0, "gridRow": 7 }
                ]
            }
        }
    }

    function validDimension(value, minimum, maximum) {
        var number = Number(value)
        return isFinite(number) && Math.floor(number) === number &&
                number >= minimum && number <= maximum
    }

    function clampInteger(value, minimum, maximum, fallback) {
        var number = Number(value)
        return isFinite(number) ? Math.max(minimum, Math.min(maximum, Math.round(number))) : fallback
    }

    function normalizePreferences() {
        if (["material-you", "nightfox", "noir", "desert", "ocean", "rose"].indexOf(theme) < 0)
            theme = "material-you"
        island.compactWidth = clampInteger(island.compactWidth, 140, 500, 208)
        island.compactHeight = clampInteger(island.compactHeight, 36, 100, 50)
        island.expandedWidth = clampInteger(island.expandedWidth, 280, 760, 390)
        island.expandedHeight = clampInteger(island.expandedHeight, 140, 420, 204)
        island.topOffset = clampInteger(island.topOffset, 0, 80, 8)
        island.radius = clampInteger(island.radius, 12, 80, 26)
        island.padding = clampInteger(island.padding, 6, 36, 16)
        island.spacing = clampInteger(island.spacing, 4, 28, 12)
        island.albumArtSize = clampInteger(island.albumArtSize, 40, 120, 64)
        island.statusIndicatorOrder = cleanStatusIndicatorOrder(island.statusIndicatorOrder)
        if (["HH:mm", "hh:mm AP"].indexOf(clock.timeFormat) < 0)
            clock.timeFormat = "HH:mm"
        if (["ddd, d MMM", "yyyy-MM-dd", "dddd, d MMMM"].indexOf(clock.dateFormat) < 0)
            clock.dateFormat = "ddd, d MMM"
        motion.islandDuration = clampInteger(motion.islandDuration, 0, 600, 220)
        motion.panelDuration = clampInteger(motion.panelDuration, 0, 600, 180)
        launcher.width = clampInteger(launcher.width, 320, 900, 540)
        launcher.maxResults = clampInteger(launcher.maxResults, 1, 20, 7)
        notifications.maxVisible = clampInteger(notifications.maxVisible, 1, 20, 5)
        controlCenter.width = clampInteger(controlCenter.width, 320, 720, 420)
        controlCenter.height = clampInteger(controlCenter.height, 320, 900, 520)
        controlCenter.radius = clampInteger(controlCenter.radius, 8, 48, 28)
        if (["Balanced", "Compact", "Media-focused", "Custom"].indexOf(controlCenter.preset) < 0)
            controlCenter.preset = "Balanced"
        var normalizedTiles = cleanTiles(controlCenter.tiles)
        if (JSON.stringify(normalizedTiles) !== JSON.stringify(controlCenter.tiles))
            controlCenter.tiles = normalizedTiles
    }

    function cleanTiles(input) {
        if (!Array.isArray(input))
            return defaultTiles()

        var result = []
        var seen = {}
        for (var index = 0; index < input.length; index++) {
            var entry = input[index]
            if (!entry || typeof entry !== "object" ||
                    supportedTiles.indexOf(entry.id) < 0 || seen[entry.id])
                continue
            var size = ["compact", "normal", "large"].indexOf(entry.size) >= 0 ? entry.size : "normal"
            var column = size === "compact" ? Number(entry.gridColumn) : 0
            var row = Number(entry.gridRow)
            if (!validDimension(column, 0, 1) || !validDimension(row, 0, 20) ||
                    !canPlaceTile(result, size, column, row)) {
                var slot = findAvailableSlot(result, size, index)
                column = slot.column
                row = slot.row
            }
            result.push({
                "id": entry.id,
                "size": size,
                "gridColumn": column,
                "gridRow": row
            })
            seen[entry.id] = true
        }

        if (result.length === 0)
            return defaultTiles()
        return result
    }

    function canPlaceTile(tiles, size, column, row, excludedIndex) {
        var span = size === "compact" ? 1 : 2
        if (!validDimension(row, 0, 20) || !validDimension(column, 0, 1) ||
                column + span > 2)
            return false
        for (var index = 0; index < tiles.length; index++) {
            if (index === excludedIndex)
                continue
            var tile = tiles[index]
            if (Number(tile.gridRow) !== row)
                continue
            var otherSpan = tile.size === "compact" ? 1 : 2
            if (column < Number(tile.gridColumn) + otherSpan &&
                    Number(tile.gridColumn) < column + span)
                return false
        }
        return true
    }

    function findAvailableSlot(tiles, size, startRow) {
        var span = size === "compact" ? 1 : 2
        for (var row = Math.max(0, Math.min(20, startRow)); row <= 20; row++) {
            for (var column = 0; column <= 2 - span; column++) {
                if (canPlaceTile(tiles, size, column, row))
                    return { column: column, row: row }
            }
        }
        return { column: 0, row: 20 }
    }

    function validLayout(tiles) {
        if (!Array.isArray(tiles) || tiles.length === 0)
            return false
        var seen = {}
        for (var index = 0; index < tiles.length; index++) {
            var tile = tiles[index]
            if (!tile || supportedTiles.indexOf(tile.id) < 0 || seen[tile.id] ||
                    ["compact", "normal", "large"].indexOf(tile.size) < 0 ||
                    !validDimension(tile.gridColumn, 0, 1) ||
                    !validDimension(tile.gridRow, 0, 20) ||
                    !canPlaceTile(tiles.slice(0, index), tile.size, tile.gridColumn, tile.gridRow))
                return false
            seen[tile.id] = true
        }
        return true
    }

    function cleanStatusIndicatorOrder(input) {
        var supported = ["network", "bluetooth", "audio", "battery"]
        if (!Array.isArray(input))
            return supported

        var result = []
        for (var index = 0; index < input.length; index++) {
            if (supported.indexOf(input[index]) >= 0 &&
                    result.indexOf(input[index]) < 0)
                result.push(input[index])
        }
        for (var supportedIndex = 0; supportedIndex < supported.length; supportedIndex++) {
            if (result.indexOf(supported[supportedIndex]) < 0)
                result.push(supported[supportedIndex])
        }
        return result
    }

    function moveStatusIndicator(indicatorId, offset) {
        var order = cleanStatusIndicatorOrder(island.statusIndicatorOrder)
        var index = order.indexOf(indicatorId)
        var targetIndex = index + offset
        if (index < 0 || targetIndex < 0 || targetIndex >= order.length)
            return false
        var moved = order.splice(index, 1)[0]
        order.splice(targetIndex, 0, moved)
        island.statusIndicatorOrder = order
        return true
    }

    function defaultTiles() {
        return [
            { "id": "audio", "size": "normal", "gridColumn": 0, "gridRow": 0 },
            { "id": "media", "size": "normal", "gridColumn": 0, "gridRow": 1 },
            { "id": "appearance", "size": "normal", "gridColumn": 0, "gridRow": 2 },
            { "id": "motion", "size": "normal", "gridColumn": 0, "gridRow": 3 },
            { "id": "wifi", "size": "normal", "gridColumn": 0, "gridRow": 4 },
            { "id": "bluetooth", "size": "normal", "gridColumn": 0, "gridRow": 5 },
            { "id": "brightness", "size": "normal", "gridColumn": 0, "gridRow": 6 },
            { "id": "notifications", "size": "normal", "gridColumn": 0, "gridRow": 7 }
        ]
    }

    function currentTiles() {
        return cleanTiles(controlCenter.tiles)
    }

    function tileHeight(size, id) {
        if (id === "wifi")
            return size === "large" ? 256 : size === "compact" ? 196 : 224
        if (id === "bluetooth")
            return size === "large" ? 184 : size === "compact" ? 120 : 152
        if (id === "brightness")
            return size === "large" ? 132 : size === "compact" ? 80 : 100
        if (id === "notifications")
            return size === "large" ? 280 : size === "compact" ? 132 : 196
        if (size === "compact")
            return 76
        if (size === "large")
            return 170
        return 128
    }

    function saveTiles(nextTiles, presetName) {
        var cleaned = cleanTiles(nextTiles)
        if (!Array.isArray(nextTiles) || cleaned.length !== nextTiles.length ||
                !validLayout(nextTiles)) {
            layoutMessage = "That change would create an invalid or overlapping tile layout."
            return false
        }
        layoutMessage = ""
        var before = currentTiles()
        var nextPreset = presetName || "Custom"
        var layoutChanged = JSON.stringify(before) !== JSON.stringify(cleaned)
        if (layoutChanged || controlCenter.preset !== nextPreset) {
            layoutHistory = layoutHistory.concat([{
                tiles: before,
                preset: controlCenter.preset
            }]).slice(-20)
        }
        if (layoutChanged)
            controlCenter.tiles = cleaned
        controlCenter.preset = nextPreset
        return true
    }

    function moveTile(fromIndex, toIndex) {
        var tiles = currentTiles()
        if (!validDimension(fromIndex, 0, tiles.length - 1) ||
                !validDimension(toIndex, 0, tiles.length - 1))
            return false
        if (fromIndex === toIndex)
            return true
        var moved = tiles[fromIndex]
        var target = tiles[toIndex]
        var column = moved.gridColumn
        var row = moved.gridRow
        moved.gridColumn = target.gridColumn
        moved.gridRow = target.gridRow
        target.gridColumn = column
        target.gridRow = row
        return saveTiles(tiles, "")
    }

    function moveTileTo(index, column, row) {
        var tiles = currentTiles()
        if (!validDimension(index, 0, tiles.length - 1) ||
                !validDimension(column, 0, 1) || !validDimension(row, 0, 20)) {
            layoutMessage = "Grid positions must use columns 1–2 and rows 1–21."
            return false
        }
        var tile = tiles[index]
        if (tile.size !== "compact" && column !== 0) {
            layoutMessage = "Normal and large tiles span both columns."
            return false
        }
        if (tile.gridColumn === column && tile.gridRow === row)
            return true
        var targetIndex = tiles.findIndex(function(other, otherIndex) {
            return otherIndex !== index && other.gridRow === row &&
                column < other.gridColumn + (other.size === "compact" ? 1 : 2) &&
                other.gridColumn < column + (tile.size === "compact" ? 1 : 2)
        })
        if (targetIndex >= 0) {
            var target = tiles[targetIndex]
            var otherTiles = tiles.filter(function(_, otherIndex) {
                return otherIndex !== index && otherIndex !== targetIndex
            })
            var canSwap = target.size === "compact" &&
                canPlaceTile(otherTiles, tile.size, target.gridColumn, target.gridRow) &&
                canPlaceTile(otherTiles, target.size, tile.gridColumn, tile.gridRow)
            if (!canSwap) {
                layoutMessage = "Tiles cannot be swapped without overlapping."
                return false
            }
            var previousColumn = tile.gridColumn
            var previousRow = tile.gridRow
            tile.gridColumn = target.gridColumn
            tile.gridRow = target.gridRow
            target.gridColumn = previousColumn
            target.gridRow = previousRow
        } else {
            tile.gridColumn = column
            tile.gridRow = row
        }
        return saveTiles(tiles, "")
    }

    function resizeTile(index, size) {
        var tiles = currentTiles()
        if (!validDimension(index, 0, tiles.length - 1) ||
                ["compact", "normal", "large"].indexOf(size) < 0)
            return false
        var tile = tiles[index]
        if (size === tile.size)
            return true
        var oldSize = tile.size
        var oldColumn = tile.gridColumn
        var oldRow = tile.gridRow
        tile.size = size
        if (size !== "compact")
            tile.gridColumn = 0
        if (!canPlaceTile(tiles.filter(function(_, tileIndex) { return tileIndex !== index }),
                tile.size, tile.gridColumn, tile.gridRow)) {
            tile.size = oldSize
            tile.gridColumn = oldColumn
            tile.gridRow = oldRow
            layoutMessage = "Resize blocked because another tile occupies that grid space."
            return false
        }
        return saveTiles(tiles, "")
    }

    function setTileEnabled(id, enabled) {
        if (supportedTiles.indexOf(id) < 0) {
            console.warn("SettingsService: rejected unknown Control Center tile:", id)
            return false
        }

        var tiles = currentTiles()
        var index = tiles.findIndex(function(tile) { return tile.id === id })
        if (enabled && index < 0) {
            var nextRow = tiles.reduce(function(maxRow, tile) {
                return Math.max(maxRow, tile.gridRow)
            }, -1) + 1
            if (nextRow > 20)
                return false
            tiles.push({ "id": id, "size": "normal", "gridColumn": 0, "gridRow": nextRow })
        }
        else if (!enabled && index >= 0) {
            if (tiles.length === 1) {
                console.warn("SettingsService: at least one Control Center tile must remain enabled.")
                return false
            }
            tiles.splice(index, 1)
        }
        return saveTiles(tiles, "")
    }

    function applyPreset(name) {
        var layouts = {
            "Balanced": defaultTiles(),
            "Compact": [
                { "id": "audio", "size": "compact", "gridColumn": 0, "gridRow": 0 },
                { "id": "appearance", "size": "compact", "gridColumn": 1, "gridRow": 0 },
                { "id": "motion", "size": "compact", "gridColumn": 0, "gridRow": 1 },
                { "id": "media", "size": "compact", "gridColumn": 1, "gridRow": 1 },
                { "id": "wifi", "size": "compact", "gridColumn": 0, "gridRow": 2 },
                { "id": "bluetooth", "size": "compact", "gridColumn": 1, "gridRow": 2 },
                { "id": "brightness", "size": "compact", "gridColumn": 0, "gridRow": 3 },
                { "id": "notifications", "size": "compact", "gridColumn": 1, "gridRow": 3 }
            ],
            "Media-focused": [
                { "id": "media", "size": "large", "gridColumn": 0, "gridRow": 0 },
                { "id": "audio", "size": "normal", "gridColumn": 0, "gridRow": 1 },
                { "id": "appearance", "size": "compact", "gridColumn": 0, "gridRow": 2 },
                { "id": "motion", "size": "compact", "gridColumn": 1, "gridRow": 2 },
                { "id": "wifi", "size": "compact", "gridColumn": 0, "gridRow": 3 },
                { "id": "bluetooth", "size": "compact", "gridColumn": 1, "gridRow": 3 },
                { "id": "brightness", "size": "compact", "gridColumn": 0, "gridRow": 4 },
                { "id": "notifications", "size": "compact", "gridColumn": 1, "gridRow": 4 }
            ]
        }
        if (!layouts[name]) {
            console.warn("SettingsService: unknown layout preset:", name)
            return false
        }
        return saveTiles(layouts[name], name)
    }

    function tidyLayout() {
        var ordered = ["wifi", "bluetooth", "audio", "brightness", "media", "notifications", "appearance", "motion"]
        var tiles = currentTiles().sort(function(left, right) {
            return ordered.indexOf(left.id) - ordered.indexOf(right.id)
        })
        for (var index = 0; index < tiles.length; index++)
        {
            tiles[index].size = "normal"
            tiles[index].gridColumn = 0
            tiles[index].gridRow = index
        }
        var balanced = JSON.stringify(tiles) === JSON.stringify(defaultTiles())
        return saveTiles(tiles, balanced ? "Balanced" : "Custom")
    }

    function undoLayout() {
        if (layoutHistory.length === 0)
            return false
        var previous = layoutHistory[layoutHistory.length - 1]
        if (!previous || !Array.isArray(previous.tiles) ||
                ["Balanced", "Compact", "Media-focused", "Custom"].indexOf(previous.preset) < 0) {
            console.warn("SettingsService: discarded an invalid Control Center undo snapshot.")
            layoutHistory = layoutHistory.slice(0, -1)
            return false
        }
        layoutHistory = layoutHistory.slice(0, -1)
        controlCenter.tiles = cleanTiles(previous.tiles)
        controlCenter.preset = previous.preset
        return true
    }

    function resetLayout() {
        return saveTiles(defaultTiles(), "Balanced")
    }

    Component.onCompleted: {
        if (!storagePath)
            console.warn("SettingsService: no absolute XDG_CONFIG_HOME or HOME was inherited; settings will not persist.")
        normalizePreferences()
    }
}

import QtQuick
import Quickshell.Io

QtObject {
    id: brightnessService

    property bool available: false
    property bool loading: true
    property bool operationPending: false
    property var monitoringClients: []
    property real value: 0
    property string failureMessage: ""
    property int requestedPercent: -1
    property int appliedPercent: -1
    property bool refreshQueued: false
    property bool writeFailed: false
    signal stateChanged()

    readonly property string status: loading ? "Loading"
        : !available ? "Unavailable"
        : operationPending ? "Applying"
        : "Available"

    function refresh() {
        if (readProcess.running) {
            refreshQueued = true
            return
        }
        readProcess.exec(["brightnessctl", "--class=backlight", "--machine-readable"])
    }

    function runQueuedRefresh() {
        if (!refreshQueued)
            return
        refreshQueued = false
        refresh()
    }

    function setMonitoring(client, active) {
        var clients = monitoringClients.slice()
        var index = clients.indexOf(client)
        if (active && index < 0)
            clients.push(client)
        else if (!active && index >= 0)
            clients.splice(index, 1)
        monitoringClients = clients
        if (active)
            refresh()
    }

    function acceptRead(output) {
        var line = output.trim().split(/\r?\n/).filter(function(entry) {
            return entry.length > 0
        })[0]
        if (!line) {
            failRead("No controllable backlight was reported by brightnessctl.")
            return
        }

        var fields = line.split(",")
        var current = Number(fields.length > 2 ? fields[2] : NaN)
        var maximum = Number(fields.length > 3 ? fields[3] : NaN)
        if (fields.length < 5 || !isFinite(current) || !isFinite(maximum) ||
                maximum <= 0 || fields[1] !== "backlight") {
            failRead("brightnessctl returned invalid backlight data.")
            return
        }

        value = Math.max(0, Math.min(1, current / maximum))
        available = true
        loading = false
        operationPending = false
        requestedPercent = -1
        if (!writeFailed)
            failureMessage = ""
        stateChanged()
    }

    function failRead(message) {
        available = false
        loading = false
        operationPending = false
        requestedPercent = -1
        refreshQueued = false
        failureMessage = message
        stateChanged()
    }

    function setValue(nextValue) {
        if (!available || !isFinite(Number(nextValue))) {
            if (!available)
                failureMessage = "Brightness control is unavailable."
            return false
        }
        requestedPercent = Math.round(Math.max(0, Math.min(1, Number(nextValue))) * 100)
        operationPending = true
        writeFailed = false
        failureMessage = ""
        debounce.start()
        return true
    }

    function applyRequestedValue() {
        if (!available || requestedPercent < 0 || writeProcess.running)
            return
        appliedPercent = requestedPercent
        writeProcess.exec([
            "brightnessctl", "--class=backlight", "set", appliedPercent + "%"
        ])
    }

    function handleWriteExit(exitCode) {
        if (exitCode === 0) {
            if (requestedPercent >= 0 && requestedPercent !== appliedPercent)
                applyRequestedValue()
            else
                refresh()
        } else {
            operationPending = false
            requestedPercent = -1
            writeFailed = true
            failureMessage = "Brightness change failed; check backlight permissions."
            stateChanged()
            refresh()
        }
    }

    Timer {
        id: debounce
        interval: 140
        repeat: false
        onTriggered: brightnessService.applyRequestedValue()
    }

    Timer {
        interval: 5000
        repeat: true
        running: brightnessService.monitoringClients.length > 0 &&
                brightnessService.available && !brightnessService.operationPending
        onTriggered: brightnessService.refresh()
    }

    Process {
        id: readProcess
        stdout: StdioCollector {
            onStreamFinished: brightnessService.acceptRead(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                brightnessService.failRead(
                    "brightnessctl is unavailable, no backlight exists, or access was denied."
                )
            brightnessService.runQueuedRefresh()
        }
    }

    Process {
        id: writeProcess
        onExited: function(exitCode, exitStatus) {
            brightnessService.handleWriteExit(exitCode)
        }
    }

    Component.onCompleted: refresh()
}

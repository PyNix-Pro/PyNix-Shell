import QtQuick
import Quickshell.Io

QtObject {
    id: applicationService

    required property var settings
    readonly property string helperPath: settings.storagePath
        ? settings.storagePath.replace(/\/settings\.json$/, "/scripts/desktop-apps.py") : ""
    property var applications: []
    property bool loading: false
    property bool launching: false
    property bool launcherAvailable: false
    property string errorMessage: ""
    property string pendingDesktopId: ""
    signal launchRequested(string desktopId)

    function refresh() {
        if (!helperPath) {
            errorMessage = "The installed desktop application helper path is unavailable."
            return
        }
        if (listProcess.running)
            return
        loading = true
        errorMessage = ""
        listProcess.exec(["python3", helperPath, "list"])
    }

    function acceptList(output) {
        try {
            var result = JSON.parse(output)
            if (!result || !Array.isArray(result.applications) ||
                    typeof result.launcherAvailable !== "boolean")
                throw new Error("Unexpected desktop application list.")
            applications = result.applications.filter(function(app) {
                return app && typeof app.desktopId === "string" &&
                        typeof app.name === "string"
            })
            launcherAvailable = result.launcherAvailable
            if (!launcherAvailable)
                errorMessage = "gtk-launch/gtk4-launch is unavailable; applications cannot be started."
        } catch (error) {
            applications = []
            errorMessage = "Could not read installed desktop applications: " + error
        }
        loading = false
    }

    function launch(desktopId) {
        if (launching)
            return false
        if (!launcherAvailable || !applications.some(function(app) {
            return app.desktopId === desktopId
        })) {
            errorMessage = "The selected application is unavailable."
            return false
        }
        errorMessage = ""
        pendingDesktopId = desktopId
        launching = true
        launchProcess.exec(["python3", helperPath, "launch", desktopId])
        return true
    }

    Process {
        id: listProcess
        stdout: StdioCollector {
            onStreamFinished: applicationService.acceptList(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    applicationService.errorMessage = text.trim()
            }
        }
        onExited: function(exitCode) {
            applicationService.loading = false
            if (exitCode !== 0 && !applicationService.errorMessage)
                applicationService.errorMessage = "Desktop application discovery failed."
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: launchProcess
        property string requestedDesktopId: ""
        onExited: function(exitCode) {
            applicationService.launching = false
            if (exitCode === 0) {
                applicationService.launchRequested(applicationService.pendingDesktopId)
            } else {
                var details = launchStderr.text.trim()
                applicationService.errorMessage = details
                    ? "The desktop launcher failed: " + details
                    : "The desktop launcher could not start the selected application."
            }
        }
        stderr: StdioCollector {
            id: launchStderr
        }
    }
}

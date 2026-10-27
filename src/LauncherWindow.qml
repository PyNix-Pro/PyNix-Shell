import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: window

    required property var settings
    required property var themeService
    required property var applicationService
    property bool opened: false
    property string searchText: ""

    title: "PyNix Shell Applications"
    width: settings.launcher.width
    height: 560
    minimumSize: Qt.size(320, 360)
    visible: opened

    function filteredApplications() {
        var query = searchText.trim().toLowerCase()
        var matches = applicationService.applications.filter(function(app) {
            return !query || (app.name + " " + app.comment + " " + app.desktopId)
                .toLowerCase().indexOf(query) >= 0
        })
        return matches.slice(0, settings.launcher.maxResults)
    }

    onOpenedChanged: {
        if (opened) {
            searchText = ""
            applicationService.refresh()
            searchField.forceActiveFocus()
        }
    }

    Connections {
        target: applicationService
        function onLaunchRequested() {
            window.opened = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: themeService.palette.background

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: "Applications"
                color: themeService.palette.primaryText
                font.pixelSize: 20
                font.bold: true
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Search installed applications"
                Accessible.name: "Search applications"
                onTextChanged: window.searchText = text
                Keys.onEscapePressed: function(event) {
                    event.accepted = true
                    window.opened = false
                }
                Keys.onReturnPressed: function(event) {
                    var matches = window.filteredApplications()
                    if (matches.length > 0 && applicationService.launch(matches[0].desktopId))
                        event.accepted = true
                }
            }

            Label {
                Layout.fillWidth: true
                visible: applicationService.loading
                text: "Reading installed desktop entries…"
                color: themeService.palette.secondaryText
            }

            Label {
                Layout.fillWidth: true
                visible: !applicationService.loading && !applicationService.launcherAvailable
                text: applicationService.errorMessage ||
                    "Application launch support is unavailable (gtk-launch/gtk4-launch not found)."
                color: themeService.palette.warning
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                visible: !applicationService.loading &&
                    applicationService.launcherAvailable &&
                    window.filteredApplications().length === 0
                text: "No matching applications."
                color: themeService.palette.secondaryText
            }

            ListView {
                id: applicationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: window.filteredApplications()
                spacing: 4

                delegate: ItemDelegate {
                    required property var modelData
                    width: applicationList.width
                    enabled: applicationService.launcherAvailable && !applicationService.launching
                    highlighted: activeFocus
                    onClicked: applicationService.launch(modelData.desktopId)
                    Accessible.name: "Launch " + modelData.name

                    contentItem: RowLayout {
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 10
                            color: themeService.palette.selected
                            Label {
                                anchors.centerIn: parent
                                text: modelData.name.length ? modelData.name[0].toUpperCase() : "•"
                                color: themeService.palette.accent
                                font.bold: true
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: themeService.palette.primaryText
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: modelData.comment || modelData.desktopId
                                color: themeService.palette.secondaryText
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                    background: Rectangle {
                        radius: 12
                        color: parent.activeFocus || parent.hovered
                            ? themeService.palette.hover : "transparent"
                        border.width: parent.activeFocus ? 1 : 0
                        border.color: themeService.palette.accent
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: applicationService.errorMessage.length > 0 &&
                    applicationService.launcherAvailable
                text: applicationService.errorMessage
                color: themeService.palette.error
                wrapMode: Text.WordWrap
            }
        }
    }
}

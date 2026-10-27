import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: notificationService

    property int maxHistory: 50
    readonly property var notifications: server.trackedNotifications.values
    readonly property int count: notifications.length

    signal notificationReceived(var notification)
    signal changed()

    function dismiss(notification) {
        if (notification && server.trackedNotifications.indexOf(notification) >= 0)
            notification.dismiss()
    }

    function clearAll() {
        var current = server.trackedNotifications.values.slice()
        for (var index = 0; index < current.length; index++)
            current[index].dismiss()
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        keepOnReload: true

        onNotification: function(notification) {
            notification.tracked = true
            var active = server.trackedNotifications.values
            while (active.length > notificationService.maxHistory) {
                active[0].expire()
                active = server.trackedNotifications.values
            }
            notificationService.notificationReceived(notification)
            notificationService.changed()
        }
    }

    Connections {
        target: server.trackedNotifications
        function onObjectInsertedPost() {
            notificationService.changed()
        }
        function onObjectRemovedPost() {
            notificationService.changed()
        }
    }
}

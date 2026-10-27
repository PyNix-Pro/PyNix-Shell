import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: mediaService

    readonly property var activePlayer: choosePlayer()
    readonly property bool available: activePlayer !== null
    readonly property bool playing: activePlayer ? activePlayer.isPlaying : false
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "Unknown title") : "No media playing"
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || "Unknown artist") : ""
    readonly property string album: activePlayer ? activePlayer.trackAlbum : ""
    readonly property string artworkUrl: activePlayer ? activePlayer.trackArtUrl : ""
    readonly property real position: activePlayer ? activePlayer.position : 0
    readonly property real duration: activePlayer ? activePlayer.length : 0
    readonly property bool canTogglePlaying: activePlayer ? activePlayer.canTogglePlaying : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false
    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false

    function choosePlayer() {
        var players = Mpris.players.values
        for (var index = 0; index < players.length; index++) {
            if (players[index].isPlaying)
                return players[index]
        }
        return players.length > 0 ? players[0] : null
    }

    function playPause() {
        if (!activePlayer || !activePlayer.canTogglePlaying)
            return
        if (activePlayer.isPlaying)
            activePlayer.pause()
        else
            activePlayer.play()
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext)
            activePlayer.next()
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious)
            activePlayer.previous()
    }

    Timer {
        interval: 1000
        repeat: true
        running: mediaService.playing
        onTriggered: {
            if (mediaService.activePlayer)
                mediaService.activePlayer.positionChanged()
        }
    }
}

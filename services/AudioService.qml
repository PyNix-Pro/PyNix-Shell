import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: audioService

    readonly property var output: Pipewire.defaultAudioSink
    readonly property bool available: output !== null && output.ready && output.audio !== null
    readonly property bool muted: available ? output.audio.muted : false
    readonly property real volume: available ? output.audio.volume : 0

    PwObjectTracker {
        objects: [audioService.output]
    }

    function setVolume(value) {
        if (!available)
            return
        output.audio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (available)
            output.audio.muted = !output.audio.muted
    }
}

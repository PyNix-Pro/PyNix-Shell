import QtQuick

QtObject {
    id: themeService

    property string activeTheme: "material-you"
    property var palette: ({
        background: "#0d1117",
        surface: "#121821",
        secondarySurface: "#1a2330",
        primaryText: "#f3f5f7",
        secondaryText: "#bfc8d4",
        mutedText: "#8d98a8",
        border: "#2d3947",
        accent: "#7ba8ff",
        accentForeground: "#ebf2ff",
        selected: "#3d6ee8",
        hover: "#273447",
        success: "#64d39d",
        warning: "#e9c574",
        error: "#f08a8a"
    })

    property var themes: ({
        "material-you": {
            background: "#0d1117",
            surface: "#121821",
            secondarySurface: "#1a2330",
            primaryText: "#f3f5f7",
            secondaryText: "#bfc8d4",
            mutedText: "#8d98a8",
            border: "#2d3947",
            accent: "#7ba8ff",
            accentForeground: "#ebf2ff",
            selected: "#3d6ee8",
            hover: "#273447",
            success: "#64d39d",
            warning: "#e9c574",
            error: "#f08a8a"
        },
        "nightfox": {
            background: "#111827",
            surface: "#162131",
            secondarySurface: "#1d2b3d",
            primaryText: "#e5e7eb",
            secondaryText: "#cbd5e1",
            mutedText: "#94a3b8",
            border: "#2d3a4d",
            accent: "#7dd3fc",
            accentForeground: "#ecfeff",
            selected: "#38bdf8",
            hover: "#1e2f44",
            success: "#86efac",
            warning: "#facc15",
            error: "#fda4af"
        },
        "noir": {
            background: "#0b0b0d",
            surface: "#121316",
            secondarySurface: "#191c21",
            primaryText: "#f4f4f5",
            secondaryText: "#d4d4d8",
            mutedText: "#a1a1aa",
            border: "#2a2a2d",
            accent: "#d4d4d8",
            accentForeground: "#171717",
            selected: "#f5f5f5",
            hover: "#1f2126",
            success: "#a7f3d0",
            warning: "#fde68a",
            error: "#fca5a5"
        },
        "desert": {
            background: "#1b1713",
            surface: "#2b221d",
            secondarySurface: "#382d29",
            primaryText: "#f8f3ea",
            secondaryText: "#e7d9c6",
            mutedText: "#d0b899",
            border: "#5d483d",
            accent: "#f4b267",
            accentForeground: "#3b2a1d",
            selected: "#f59e0b",
            hover: "#48382f",
            success: "#7dd3a5",
            warning: "#fcd34d",
            error: "#fca5a5"
        },
        "ocean": {
            background: "#071a20",
            surface: "#0c2732",
            secondarySurface: "#123a45",
            primaryText: "#ecfeff",
            secondaryText: "#cffafe",
            mutedText: "#a5f3fc",
            border: "#1f4f5c",
            accent: "#5eead4",
            accentForeground: "#042f2e",
            selected: "#2dd4bf",
            hover: "#123f4a",
            success: "#34d399",
            warning: "#fbbf24",
            error: "#fda4af"
        },
        "rose": {
            background: "#1c1117",
            surface: "#281b20",
            secondarySurface: "#3a232c",
            primaryText: "#fff1f2",
            secondaryText: "#fbcfe8",
            mutedText: "#f9a8d4",
            border: "#5b3945",
            accent: "#f472b6",
            accentForeground: "#fff1f2",
            selected: "#ec4899",
            hover: "#4d2c3a",
            success: "#86efac",
            warning: "#fda4af",
            error: "#fb7185"
        }
    })

    signal themeChanged(string name)

    function applyTheme(name) {
        if (!themes[name]) {
            console.warn("ThemeService: unknown theme requested:", name)
            return
        }
        activeTheme = name
        var selectedTheme = themes[name]
        palette = selectedTheme
        themeChanged(name)
    }

    Component.onCompleted: {
        applyTheme(activeTheme)
    }
}

#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

required_theme_ids = {
    "material-you",
    "nightfox",
    "noir",
    "desert",
    "ocean",
    "rose",
}
required_palette_keys = {
    "background",
    "surface",
    "secondarySurface",
    "primaryText",
    "secondaryText",
    "mutedText",
    "border",
    "accent",
    "accentForeground",
    "selected",
    "hover",
    "success",
    "warning",
    "error",
}


def require_json(path: Path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except Exception as exc:  # pragma: no cover - test should fail loudly
        raise AssertionError(f"Failed to parse JSON: {path}: {exc}") from exc


config = require_json(ROOT / "config" / "defaults.json")
assert config["theme"] in required_theme_ids, "Default theme must be one of the built-in themes."
assert "island" in config
assert "motion" in config
assert "notifications" in config
assert "clock" in config
assert "launcher" in config
assert "controlCenter" in config
assert set(config["island"]) >= {
    "compactWidth", "compactHeight", "expandedWidth", "expandedHeight",
    "topOffset", "radius", "padding", "spacing", "showStatusIndicators",
    "statusIndicatorOrder", "statusIndicatorVisibility",
    "showAlbumArt", "albumArtSize", "hoverLift",
}
assert config["island"]["statusIndicatorOrder"] == ["network", "bluetooth", "audio", "battery"]
assert set(config["island"]["statusIndicatorVisibility"]) == {"network", "bluetooth", "audio", "battery"}
assert set(config["clock"]) >= {"showClock", "timeFormat", "showDate", "dateFormat"}
assert set(config["motion"]) >= {
    "animationsEnabled", "reducedMotion", "lowPerformance",
    "islandDuration", "panelDuration",
}
assert set(config["controlCenter"]) >= {"width", "height", "radius", "preset", "tiles"}
assert set(config["launcher"]) >= {"width", "maxResults"}
assert set(config["notifications"]) >= {"maxVisible"}
assert 140 <= config["island"]["compactWidth"] <= 500
assert 36 <= config["island"]["compactHeight"] <= 100
assert 320 <= config["controlCenter"]["width"] <= 720
assert 320 <= config["controlCenter"]["height"] <= 900
supported_control_tiles = {
    "audio", "media", "appearance", "motion", "wifi", "bluetooth", "brightness",
    "notifications",
}
assert {tile["id"] for tile in config["controlCenter"]["tiles"]} == supported_control_tiles
assert all(tile["id"] in supported_control_tiles
           and tile["size"] in {"compact", "normal", "large"}
           for tile in config["controlCenter"]["tiles"])
assert all(
    tile["gridColumn"] in {0, 1} and 0 <= tile["gridRow"] <= 20
    and (tile["size"] == "compact" or tile["gridColumn"] == 0)
    for tile in config["controlCenter"]["tiles"]
)
assert len({(tile["gridRow"], tile["gridColumn"]) for tile in config["controlCenter"]["tiles"]}) == len(
    config["controlCenter"]["tiles"]
)
occupied_cells = set()
for tile in config["controlCenter"]["tiles"]:
    for column in range(tile["gridColumn"], tile["gridColumn"] + (1 if tile["size"] == "compact" else 2)):
        cell = (tile["gridRow"], column)
        assert cell not in occupied_cells, f"Default tile positions overlap at {cell}"
        occupied_cells.add(cell)

theme_service_qml = (ROOT / "services" / "ThemeService.qml").read_text(encoding="utf-8")
settings_service_qml = (ROOT / "services" / "SettingsService.qml").read_text(encoding="utf-8")
settings_window_qml = (ROOT / "src" / "SettingsWindow.qml").read_text(encoding="utf-8")
for theme_name in sorted(required_theme_ids):
    path = ROOT / "themes" / f"{theme_name}.json"
    theme = require_json(path)
    assert theme["id"] == theme_name, f"Theme id mismatch for {theme_name}"
    palette = theme["palette"]
    missing = sorted(required_palette_keys - set(palette.keys()))
    assert not missing, f"Theme {theme_name} is missing palette keys: {missing}"
    runtime_theme = re.search(
        r'"' + re.escape(theme_name) + r'"\s*:\s*\{([^}]*)\}',
        theme_service_qml,
        re.S,
    )
    assert runtime_theme, f"Runtime ThemeService is missing {theme_name}"
    runtime_palette = dict(re.findall(
        r'([A-Za-z][A-Za-z0-9]*)\s*:\s*"(#[0-9a-fA-F]{6})"',
        runtime_theme.group(1),
    ))
    assert runtime_palette == palette, f"Runtime and packaged palettes differ for {theme_name}"
    assert f'"{theme_name}"' in settings_service_qml
    assert f'"{theme_name}"' in settings_window_qml

for script_name in (
    "install.sh",
    "uninstall.sh",
    "scripts/diagnose.sh",
    "tests/test_install_safety.sh",
    "tests/test_hyprland_startup.py",
    "tests/test_start_shell.sh",
    "scripts/start-shell.sh",
    "scripts/hyprland-startup.py",
    "scripts/desktop-apps.py",
    "scripts/pynix-ipc.sh",
    "tests/test_desktop_apps.py",
):
    script_path = ROOT / script_name
    assert script_path.exists(), f"Missing script: {script_name}"
    assert script_path.stat().st_mode & 0o111, f"Script is not executable: {script_name}"

main_qml = (ROOT / "src" / "main.qml").read_text(encoding="utf-8")
media_qml = (ROOT / "services" / "MediaService.qml").read_text(encoding="utf-8")
audio_qml = (ROOT / "services" / "AudioService.qml").read_text(encoding="utf-8")
network_qml = (ROOT / "services" / "NetworkService.qml").read_text(encoding="utf-8")
bluetooth_qml = (ROOT / "services" / "BluetoothService.qml").read_text(encoding="utf-8")
battery_qml = (ROOT / "services" / "BatteryService.qml").read_text(encoding="utf-8")
brightness_qml = (ROOT / "services" / "BrightnessService.qml").read_text(encoding="utf-8")
settings_qml = (ROOT / "services" / "SettingsService.qml").read_text(encoding="utf-8")
settings_window_qml = (ROOT / "src" / "SettingsWindow.qml").read_text(encoding="utf-8")
layout_editor_qml = (ROOT / "src" / "LayoutEditor.qml").read_text(encoding="utf-8")
control_center_qml = (ROOT / "src" / "ControlCenter.qml").read_text(encoding="utf-8")
notification_qml = (ROOT / "services" / "NotificationService.qml").read_text(encoding="utf-8")
application_qml = (ROOT / "services" / "ApplicationService.qml").read_text(encoding="utf-8")
launcher_window_qml = (ROOT / "src" / "LauncherWindow.qml").read_text(encoding="utf-8")
desktop_apps_py = (ROOT / "scripts" / "desktop-apps.py").read_text(encoding="utf-8")
ipc_bridge = (ROOT / "scripts" / "pynix-ipc.sh").read_text(encoding="utf-8")

assert "ShellRoot {" in main_qml
assert "PanelWindow {" in main_qml
assert "mask: Region {" in main_qml
assert "import QtQuick.Window" not in main_qml
assert "import Quickshell.Io" in main_qml and 'target: "pynix"' in main_qml
assert "function command(name: string): string" in main_qml
for ipc_command in (
    "open-control-center", "close-control-center", "expand-island",
    "collapse-island", "open-settings", "open-theme-switcher", "open-launcher",
):
    assert f'case "{ipc_command}"' in main_qml
assert "error: unsupported PyNix Shell command" in main_qml
assert 'initialPage: shell.settingsPage' in main_qml
assert "onInitialPageChanged:" in settings_window_qml
assert "ipc call pynix command" in ipc_bridge
assert "Mpris.players.values" in media_qml
assert "activePlayer.canGoNext" in media_qml
assert "activePlayer.canGoPrevious" in media_qml
assert "Pipewire.defaultAudioSink" in audio_qml
assert "PwObjectTracker" in audio_qml
assert "import Quickshell.Services.UPower" in battery_qml
assert "UPower.devices.values" in battery_qml
assert "device.isLaptopBattery && device.ready && device.isPresent" in battery_qml
assert "battery.percentage" in battery_qml
assert "UPowerDeviceState.Charging" in battery_qml
assert "BatteryService { id: batteryService }" in main_qml
assert "networkService.status" in main_qml
assert "bluetoothService.status" in main_qml
assert "audioService.muted" in main_qml
assert "batteryService.percentage" in main_qml
assert "statusIndicatorOrder.filter" in main_qml
assert "settingsService.island.statusIndicatorVisibility[indicatorId]" in main_qml
assert "width: 18" in main_qml and 'modelData !== "battery" || dataAvailable' in main_qml
assert "settings.moveStatusIndicator(indicatorId, offset)" in settings_window_qml
assert "function moveStatusIndicator(indicatorId, offset)" in settings_qml
assert "\n    function moveStatusIndicator(indicatorId, offset)" in settings_qml
assert "island.statusIndicatorOrder = cleanStatusIndicatorOrder(island.statusIndicatorOrder)" in settings_qml
assert "import Quickshell.Networking" in network_qml
assert "Networking.devices.values" in network_qml
assert "Networking.wifiEnabled = !Networking.wifiEnabled" in network_qml
assert "network.connectWithPsk(password)" in network_qml
assert "ConnectionFailReason.NoSecrets" in network_qml
assert "network.security !== WifiSecurityType.Open" in network_qml
assert "operation timed out" in network_qml
assert '"Unavailable"' in network_qml and '"Blocked by hardware"' in network_qml
assert "console." not in network_qml, "Network authentication data must never be logged."
assert "password" not in json.dumps(config).lower(), "Wi-Fi credentials must not enter defaults."
assert "import Quickshell.Bluetooth" in bluetooth_qml
assert "Bluetooth.defaultAdapter" in bluetooth_qml
assert "adapter.enabled = requestedEnabled" in bluetooth_qml
assert "device.connected = requestedDeviceConnection" in bluetooth_qml
assert "Bluetooth operation was not confirmed" in bluetooth_qml
assert "adapter !== null" in bluetooth_qml
assert 'operationTarget === "adapter"' in bluetooth_qml
assert 'operationTarget === "device"' in bluetooth_qml
assert "Process {" in brightness_qml and "import Quickshell.Io" in brightness_qml
assert '"brightnessctl", "--class=backlight", "--machine-readable"' in brightness_qml
assert '"brightnessctl", "--class=backlight", "set", appliedPercent + "%"' in brightness_qml
assert "Math.max(0, Math.min(1, Number(nextValue)))" in brightness_qml
assert "maximum <= 0" in brightness_qml
assert "brightnessctl is unavailable, no backlight exists, or access was denied." in brightness_qml
assert "Brightness change failed; check backlight permissions." in brightness_qml
assert "interval: 5000" in brightness_qml and "monitoringClients.length > 0" in brightness_qml
assert "!brightnessService.operationPending" in brightness_qml
assert "writeFailed" in brightness_qml
assert '["sh", "-c"]' not in brightness_qml
assert '"/pynix-shell/settings.json"' in settings_qml
assert "Quickshell.env(\"XDG_CONFIG_HOME\")" in settings_qml
assert "FileView {" in settings_qml
assert "JsonAdapter {" in settings_qml
assert "XMLHttpRequest" not in settings_qml
required_settings_pages = [
    "Bar & Island", "Clock & Date", "Appearance", "Motion", "Launcher",
    "Notifications", "Control Center", "Lock Screen", "System",
]
page_positions = [settings_window_qml.index(f'title: "{title}"') for title in required_settings_pages]
assert page_positions == sorted(page_positions), "Settings pages must be registered in required order."
assert "window.filteredPages()" in settings_window_qml
assert "SettingsWindow {" in main_qml
assert "onCloseRequested: shell.settingsOpen = false" in main_qml
assert "themeService.applyTheme(settingsService.theme)" in main_qml
assert "currentTiles()" in control_center_qml
assert "Layout.row: modelData.gridRow" in control_center_qml
assert "Layout.column: modelData.gridColumn" in control_center_qml
assert "Layout.columnSpan: modelData.size === \"compact\" ? 1 : 2" in control_center_qml
assert "settings.tileHeight(modelData.size, modelData.id)" in control_center_qml
assert "networkService: networkService" in main_qml
assert "bluetoothService: bluetoothService" in main_qml
assert "brightnessService: brightnessService" in main_qml
assert "ApplicationService {" in main_qml and "NotificationService {" in main_qml
assert "LauncherWindow {" in main_qml and "onLauncherRequested: shell.launcherOpen = true" in main_qml
assert "import Quickshell.Services.Notifications" in notification_qml
assert "NotificationServer {" in notification_qml
assert "notification.tracked = true" in notification_qml
assert "notification.dismiss()" in notification_qml
assert "server.trackedNotifications.values" in notification_qml
assert "Desktop notification integration is not implemented." not in settings_window_qml
assert "settings.launcher.width" in settings_window_qml
assert "settings.launcher.maxResults" in settings_window_qml
assert "settings.notifications.maxVisible" in settings_window_qml
assert "notificationService.clearAll()" in settings_window_qml
assert "applicationService: applicationService" in main_qml
assert "notificationService: notificationService" in main_qml
assert "notificationService.count" in control_center_qml
assert "notificationService.dismiss(modelData)" in control_center_qml
assert "notifications" in settings_qml
assert '["gtk-launch", desktop_id]' in desktop_apps_py or '[executable, desktop_id]' in desktop_apps_py
assert 'Process {' in application_qml and '"python3", helperPath' in application_qml
assert "filteredApplications()" in launcher_window_qml
assert "No launcher settings are offered until" not in settings_window_qml
assert 'tileData.id === "wifi" ? wifiTile' in control_center_qml
assert 'tileData.id === "bluetooth" ? bluetoothTile' in control_center_qml
assert 'tileData.id === "brightness" ? brightnessTile' in control_center_qml
assert "networkService.failureMessage" in control_center_qml
assert "bluetoothService.failureMessage" in control_center_qml
assert "brightnessService.failureMessage" in control_center_qml
assert "Wi-Fi network password" in control_center_qml
assert "if (!visible)" in control_center_qml
assert "tileSummary(tile)" in layout_editor_qml
assert "networkService.status" in layout_editor_qml
assert "bluetoothService.status" in layout_editor_qml
assert "brightnessService.status" in layout_editor_qml
assert "NetworkManager Wi-Fi" in settings_window_qml
assert "BlueZ Bluetooth" in settings_window_qml
assert "Optional brightnessctl backlight interface." in settings_window_qml
assert "moveTile(fromIndex, toIndex)" in settings_qml
assert "resizeTile(index, size)" in settings_qml
assert "moveTileTo(index, column, row)" in settings_qml
assert "function canPlaceTile(tiles, size, column, row, excludedIndex)" in settings_qml
assert "function validLayout(tiles)" in settings_qml
assert "column + span > 2" in settings_qml
assert "function findAvailableSlot(tiles, size, startRow)" in settings_qml
assert 'layoutMessage = "Resize blocked because another tile occupies that grid space."' in settings_qml
assert "tiles: before" in settings_qml and "preset: controlCenter.preset" in settings_qml
assert "var previous = layoutHistory[layoutHistory.length - 1]" in settings_qml
assert "setTileEnabled(id, enabled)" in settings_qml
assert '"Balanced"' in settings_qml and '"Compact"' in settings_qml and '"Media-focused"' in settings_qml
assert "function tidyLayout()" in settings_qml
assert "function undoLayout()" in settings_qml
assert "function resetLayout()" in settings_qml
assert "tiles: before" in settings_qml
assert "controlCenter.preset = previous.preset" in settings_qml
assert "validDimension(value, minimum, maximum)" in settings_qml
assert "supportedTiles.indexOf(entry.id) < 0" in settings_qml
assert "function normalizePreferences()" in settings_qml
assert "JSON.stringify(normalizedTiles)" in settings_qml
assert "editor.settings.moveTile" in layout_editor_qml
assert "editor.settings.resizeTile" in layout_editor_qml
assert "editor.settings.moveTileTo" in layout_editor_qml
assert "Menu {" in layout_editor_qml and "acceptedButtons: Qt.RightButton" in layout_editor_qml
assert "Set grid position..." in layout_editor_qml
assert all(f'Resize to {size}' in layout_editor_qml for size in ("compact", "normal", "large"))
assert "onAccepted: editor.settings.moveTileTo(" in layout_editor_qml
assert "Move left" in layout_editor_qml and "Move down" in layout_editor_qml
assert "Layout.columnSpan: tileItem.modelData.size === \"compact\" ? 1 : 2" in layout_editor_qml
assert "Layout.row: tileItem.modelData.gridRow" in layout_editor_qml
assert "Layout.column: tileItem.modelData.gridColumn" in layout_editor_qml
assert "editor.settings.applyPreset(currentText)" in layout_editor_qml
assert "editor.settings.setTileEnabled(modelData, checked)" in layout_editor_qml
assert "editor.settings.tileHeight(tileItem.modelData.size, tileItem.modelData.id)" in layout_editor_qml
assert "editor.settings.supportedTiles" in layout_editor_qml
assert "Drag.keys:" in layout_editor_qml and "keys:" in layout_editor_qml
assert "settings.storagePath" in settings_window_qml

installer = (ROOT / "install.sh").read_text(encoding="utf-8")
uninstaller = (ROOT / "uninstall.sh").read_text(encoding="utf-8")
assert "pynix_validate_arch_os /etc/os-release || return 1" in installer
assert "pynix_validate_arch_os /etc/os-release || return 1" in uninstaller
assert "source \"$SCRIPT_DIR/scripts/install-safety.sh\"" in installer
assert "source \"$SCRIPT_DIR/scripts/install-safety.sh\"" in uninstaller
assert 'rm -rf -- "$config_dir"' not in uninstaller
assert "hyprland-startup.py\" install" in installer
assert "start-shell.sh\" --no-duplicate" not in installer
assert 'for entry in assets config themes services src scripts; do' in installer
assert "assets/*|config/*" in uninstaller
assert "for dir in assets config themes services src hyprland scripts tests; do" in uninstaller
assert 'for entry in README.md BUILD_SPEC.md PROGRESS.md DECISIONS.md; do' not in installer
installer_main = installer.split("main() {", 1)[1]
uninstaller_main = uninstaller.split("main() {", 1)[1]
assert installer_main.index("pynix_validate_arch_os /etc/os-release") < installer_main.index("confirm ||")
assert installer_main.index("pynix_validate_arch_os /etc/os-release") < installer_main.index("mkdir -p -- \"$config_home\"")
assert installer_main.index("pynix_report_virtualization") < installer_main.index("confirm ||")
assert installer_main.index("pynix_validate_architecture") < installer_main.index("confirm ||")
assert installer_main.index("pynix_validate_user_paths") < installer_main.index("confirm ||")
assert "require_non_root || return 1" in installer_main
assert uninstaller_main.index("pynix_validate_arch_os /etc/os-release") < uninstaller_main.index("confirm ||")
assert uninstaller_main.index("pynix_validate_architecture") < uninstaller_main.index("confirm ||")
assert uninstaller_main.index("pynix_validate_user_paths") < uninstaller_main.index("confirm ||")
assert "pynix_require_non_root || return 1" in uninstaller_main
assert uninstaller_main.index("pynix_validate_arch_os /etc/os-release") < uninstaller_main.index("remove_managed_files")
assert uninstaller_main.index("pynix_report_virtualization") < uninstaller_main.index("confirm ||")
assert 'remove_hyprland_integration "$config_dir" || return 1' in uninstaller
assert 'python3 "$helper" remove --config "$target"' in uninstaller
assert 'rm -rf -- "$backup_root"' not in uninstaller
assert "pynix_validate_vm" not in installer + uninstaller
install_safety = (ROOT / "scripts" / "install-safety.sh").read_text(encoding="utf-8")
assert "PYNIX_ALLOW_PHYSICAL" not in installer + uninstaller + install_safety
assert "physical Arch installations are supported" in install_safety
assert "Virtualization detection failed; continuing because it is informational only." in install_safety
assert "pynix_confirm_routine" in install_safety
assert "pynix_require_non_root" in install_safety
assert "pacman" in installer and "pacman" in uninstaller
assert 'pynix-shell-config-backup-v1' in installer + uninstaller
assert 'rm -rf -- "$backup_dir"' in uninstaller

print("All static config, theme, script, and QML source checks passed.")

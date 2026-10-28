# Architecture and design decisions

## Shell runtime

- Use Qt Quick/QML with one Quickshell runtime for the island, Control Center, Settings, theme switcher, and launcher. Shared runtime state avoids separate processes and duplicated integrations.
- The entry point uses Quickshell `ShellRoot` and a `PanelWindow` variant for each connected screen. The top overlay reserves no exclusive zone and applies a click-through `Region` mask so transparent panel area does not intercept desktop input.
- Settings is a focused full-screen layer-shell window with a centered rounded surface and its own click mask; Escape and the close button dismiss it without grabbing clicks across the desktop.
- The sidebar's nine sections use a single active-page state. Search filters section registration by explicit page keywords; supported preference controls bind directly to the shared settings objects.
- MPRIS is accessed through Quickshell's `Mpris` service. Prefer a currently playing player, then the first available player; check capability properties before calling controls.
- Refresh MPRIS position once per second while playing, as the Quickshell documentation recommends for non-smooth progress displays; avoid a permanent frame loop.
- PipeWire access uses the default sink with `PwObjectTracker` binding before reading or writing audio node properties.

## Persistence and configuration

- `config/defaults.json` remains the documented packaged default schema.
- Runtime user preferences are persisted with Quickshell `FileView` and `JsonAdapter` at `$XDG_CONFIG_HOME/pynix-shell/settings.json` (falling back to `~/.config/pynix-shell/settings.json`). This aligns runtime state with the installer-owned config directory and the uninstaller's explicit settings-preservation choice.
- Persisted fields cover island geometry/visibility, clock/date formats, theme, motion, Control Center dimensions and layout, and future launcher/notification preference slots. Fields without runtime integrations are not exposed as active controls.
- Control Center tile layout is a validated list of implemented tile IDs and size categories. Presets, tile enablement, Tidy, Undo, Reset, drag ordering, and accessible move controls update the same persisted model consumed by the live panel. At least one tile remains enabled.
- Malformed IDs, duplicates, unsupported sizes, and invalid dimensions are normalized or refused; the saved layout uses a vertical stack, so overlap and out-of-bounds positioning are not possible. Arbitrary grid placement is not supported.
- Settings updates must modify structured preferences, never rewrite QML source or unrelated configuration.

## Theme system

- Use one semantic palette model with consistent surface, text, border, accent, warning, success, and error tokens.
- The Control Center selects one of the six built-in theme IDs and updates the shared `ThemeService`.
- Palette definitions are still duplicated in QML; the JSON assets are not yet the runtime source of truth.

## Integrations and graceful capability handling

- MPRIS and PipeWire have source-level integrations. Their behavior is not yet guest-tested.
- Wi-Fi uses Quickshell 0.3.2 `Quickshell.Networking`, which documents a NetworkManager/D-Bus backend. The shared service uses backend device/network state and direct QML API operations; it does not build shell commands.
- Bluetooth uses Quickshell 0.3.2 `Quickshell.Bluetooth` and BlueZ/D-Bus state. The current adapter model is used for connected devices; no unsupported general scan/connect UI is claimed.
- Brightness uses optional `brightnessctl` via Quickshell `Process` argument arrays, not shell interpolation. A short trailing-edge debounce coalesces slider writes; only parsed readback is displayed as actual brightness.
- The launcher reads XDG application desktop entries with a small Python standard-library helper and delegates launches to `gtk-launch`/`gtk4-launch`. Desktop-entry IDs are validated and passed as separate process arguments; no shell command is constructed. The GTK launcher is optional and missing providers are surfaced in the UI.
- Notifications use Quickshell 0.3.2 `NotificationServer` and its tracked-notification model. The Control Center exposes active entries and dismiss actions; no persistent history or custom toast stack is claimed. Existing ownership of the Freedesktop notification D-Bus name may conflict and requires runtime validation.
- PyNix does not log or store network credentials in its settings. Quickshell documents that NetworkManager may retain a supplied PSK as a connection secret; the system's NetworkManager/secret-agent policy governs that.
- Notification delivery and launch provider availability remain runtime-unverified; the UI must surface unavailable providers and never invent application or notification data.
- The Settings launcher and notification pages intentionally show integration status rather than exposing inert controls. The lock-screen page states the shell does not own or modify the user's lock-screen configuration.
- Optional hardware is not required for the entire shell to start.
- Shell IPC uses one Quickshell 0.3.2 `IpcHandler` and a fixed string-command allowlist, rather than exposing arbitrary execution. The state changes target the existing root properties and shared windows; they never start another Quickshell instance.

## Startup and session lifecycle

- Hyprland is launched manually by the user from a TTY; PyNix Shell starts from the compositor's startup hook, not a login profile or display-manager dependency.
- The startup helper inspects Hyprland config contents and version, makes a backup, installs one idempotent marked block, and removes only that managed block. If no main config exists, create a version-matched Lua/hyprlang starter config atomically with a basic terminal/exit binding and the managed shell startup. Record a digest of the generated base after removing the integration block; only delete it on uninstall when the digest still matches, otherwise preserve user edits.
- The helper emits Lua `hl.on("hyprland.start", ...)`/`hl.exec_cmd(...)` for current Lua config and `exec-once` for supported legacy hyprlang. Optional shortcuts use documented Lua `hl.bind`/`hl.dsp.exec_cmd` calls or hyprlang `bind` lines in the same uniquely marked, backed-up block. IPC/API command forms were checked against Quickshell 0.3.2 and official Hyprland docs; live runtime parsing still requires guest validation.
- The launcher must consume the compositor's Wayland/D-Bus/runtime environment and must not overwrite it or start another D-Bus session. Use project-specific duplicate prevention and avoid restart loops.
- No `Hyprland`, `start-hyprland`, or `dbus-run-session Hyprland` workflow has been tested in the target guest. The starter config uses syntax/API forms from the official Hyprland v0.55 Lua example and v0.54 hyprlang documentation.

## Installer and development boundaries

- Keep development changes within the project workspace. Do not use the current development host for installation, activation, package installation, or system configuration.
- The maintainer uses a dedicated Arch VM for installation and GUI testing. This development workflow does not restrict the release installer.
- Final published installation target: Arch Linux on physical hardware or in a VM, plus compatible Arch-based distributions that satisfy required dependencies through pacman. Validate `/etc/os-release` via `ID` and `ID_LIKE`, plus architecture, paths, user, pacman/dependencies, and consent.
- Virtualization detection is diagnostic only and cannot reject a supported physical installation. Detected containers are unsupported and may be refused because the graphical Hyprland session is not validated there.
- The final installer may use standard sudo authentication for approved system package operations. Do not run the whole installer as root, capture sudo credentials, or allow Yes-to-All to skip safety checks.
- The installer installs only missing required `python`, `quickshell`, and `hyprland` packages after checking configured pacman repository availability and receiving routine `[Y,n,yesforall]:` consent. It uses `sudo pacman -S --needed` without custom credential handling, database refresh, full upgrade, or AUR-helper bootstrap. Optional NetworkManager, BlueZ, PipeWire, brightness, and notification components are not installed or enabled. The main install/uninstall confirmation remains a separate explicit `y`/`n` gate. Package and sudo behavior is tested with mocks only; no installer/uninstaller was executed.
- Installer confirmations share one parser and display `[Y,n,yesforall]:`. `yesforall` is case-insensitive, in-memory per process, and approves only eligible installation actions. Initial install approval may enable it for later routine dependency choices; Hyprland config edits and uninstaller/destructive cleanup require a separate explicit `y`/`n`. Empty input/EOF do not approve, invalid input is retried, and command failures still stop/report after yesforall.
- Back up user config before edits; never replace the full Hyprland config. The uninstaller may remove only PyNix-owned files/integration and must never remove shared packages.

## Evidence and validation

- Quickshell 0.3.2 official docs consulted for [`PanelWindow`](https://quickshell.org/docs/v0.3.2/types/Quickshell/PanelWindow), [`QsWindow.mask`](https://quickshell.org/docs/v0.3.2/types/Quickshell/QsWindow#mask), [`Region`](https://quickshell.org/docs/v0.3.2/types/Quickshell/Region), [`Mpris`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Mpris/Mpris), [`MprisPlayer`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Mpris/MprisPlayer), [`Pipewire`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Pipewire/Pipewire), [`PwObjectTracker`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Pipewire/PwObjectTracker), [`FileView`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/FileView), and [`JsonAdapter`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/JsonAdapter).
- Qt 6 official docs consulted for [`Drag`](https://doc.qt.io/qt-6/qml-qtquick-drag.html), [`DropArea`](https://doc.qt.io/qt-6/qml-qtquick-droparea.html), [`DragEvent`](https://doc.qt.io/qt-6/qml-qtquick-dragevent.html), and [`SpinBox`](https://doc.qt.io/qt-6/qml-qtquick-controls-spinbox.html).
- Quickshell 0.3.2 official docs consulted for [`Networking`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/Networking), [`NetworkDevice`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/NetworkDevice), [`WifiDevice`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/WifiDevice), [`WifiNetwork`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/WifiNetwork), [`ConnectionState`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/ConnectionState), and [`ConnectionFailReason`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Networking/ConnectionFailReason); NetworkManager's [wireless-device D-Bus API](https://networkmanager.dev/docs/api/latest/gdbus-org.freedesktop.NetworkManager.Device.Wireless.html) documents the access-point model.
- Quickshell 0.3.2 official docs consulted for [`Bluetooth`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Bluetooth/Bluetooth), [`BluetoothAdapter`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Bluetooth/BluetoothAdapter), [`BluetoothDevice`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Bluetooth/BluetoothDevice), [`Process`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Process), and [`StdioCollector`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/StdioCollector); BlueZ's [Adapter API](https://bluez.readthedocs.io/en/latest/adapter-api/) and [Device API](https://bluez.readthedocs.io/en/latest/device-api/) confirm the underlying model. `brightnessctl` machine-readable output and class selection were checked in its [upstream usage documentation](https://github.com/Hummer12007/brightnessctl).
- Source/API documentation review establishes intended API usage only. Integration and Settings source assertions were added but not run. No QML parser, startup workflow, NetworkManager/BlueZ D-Bus operation, backlight change, rendering, persistence, drag/drop, keyboard focus, or GUI behavior was verified in this phase.
- Performance on Intel HD Graphics 2500 has not been measured.

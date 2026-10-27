# PyNix Shell

PyNix Shell is an in-progress Quickshell/Hyprland desktop shell. Its runtime includes a layer-shell island with compact and expanded states, MPRIS playback controls, PipeWire output controls, NetworkManager Wi-Fi and BlueZ Bluetooth integrations, optional `brightnessctl` backlight control, a searchable desktop-entry launcher, Quickshell's Freedesktop notification server, a graphical nine-section Settings window, a persistent Control Center layout editor, and a validated Quickshell IPC interface. Optional Hyprland keybindings are available through installation integration. Source-level installer protections are tested; actual installation and runtime behavior remain unverified.

## Project goals

- Compact Dynamic Island anchored at the top centre of the active monitor.
- Expanded media state connected to Quickshell's MPRIS service.
- Floating Control Center with Wi-Fi, Bluetooth, audio, brightness, and notifications.
- Nine-section graphical Settings window with searchable navigation.
- Live Control Center tile ordering, size presets, Tidy, Undo, and Reset.
- Shared settings and theme service for all shell components.
- Persistent JSON configuration under the user's XDG config directories.
- Safe Arch-specific `install.sh` and `uninstall.sh` scripts.
- Static validation for scripts, config, and theme data.

## Repository layout

- `BUILD_SPEC.md` — complete build specification copied from the assignment snapshot.
- `PROGRESS.md` — implementation milestones and validation status.
- `DECISIONS.md` — architecture and dependency decisions.
- `src/` — shell runtime and UI entrypoints.
- `assets/` — project-owned runtime assets, deployed with the shell.
- `services/` — shared QML service objects.
- `config/` — defaults and user settings.
- `themes/` — built-in semantic palettes.
- `hyprland/` — explanatory integration note; the installer generates the managed entry in the user's config.
- `scripts/` — diagnostics and helper tools.
- `tests/` — validation scripts.

## Development-host safety

**Development boundary:** do not run `install.sh` or `uninstall.sh` on the current development host, install packages, alter desktop configuration/services/autostart, or activate PyNix Shell there. Workspace source edits and non-destructive checks are permitted. The project maintainer uses a dedicated Arch VM for installation and GUI testing; this is a development practice, not an end-user installation requirement.

**Supported release targets:** Arch Linux on physical hardware or in a VM, plus compatible Arch-based distributions whose package manager and runtime dependencies are supported. Virtualization detection is informational and never gates a supported physical installation. Containers are not supported; if detected, the installer refuses because a graphical Hyprland session is not established as available.

## Quick start

1. Clone the repository and enter its directory:
   ```sh
   git clone <repository-url>
   cd PyNix-Shell
   ```
2. Run `./install.sh` as the intended non-root user, review the proposed operations, and approve only the actions you want. Use `./install.sh --no-startup` to skip Hyprland startup integration, or `./install.sh --keybindings` to request the optional PyNix Shell shortcuts along with startup.
3. Start Hyprland normally. The shell source and runtime assets are deployed under the user's XDG configuration directory, so the installation does not depend on the clone path.
4. For source contributors, run the non-destructive checks below in a development environment; do not install or activate the shell on the development host.

## Installation

The installer validates Arch/Arch-compatible `/etc/os-release`, x86_64 architecture, pacman and required tools, safe user paths, and a non-root user. VM detection is informational; physical Arch and supported Arch-based installations are allowed by default. Detected containers are refused. It asks before modifying user files and backs up an existing PyNix Shell config directory. If Python, Quickshell, or Hyprland is missing, it checks that the corresponding package is available in the configured pacman repositories and offers the exact `sudo pacman -S --needed ...` operation. Sudo handles its own authentication; the installer never receives or stores the password. It does not refresh package databases, perform a system upgrade, install optional desktop services, or install an AUR helper. Startup integration has a separate confirmation and backup. Eligible routine actions support Y/N/A (Yes to All); the essential install confirmation remains an explicit Y/N choice.

Run this command as the intended user on a supported target:

```bash
./install.sh
```

The installer invokes pacman only for individually approved missing required packages, using `sudo pacman -S --needed` and ordinary sudo authentication; it never installs optional services, runs an AUR helper, or performs a system upgrade. It does not silently replace desktop components or the full Hyprland config. It deploys source, services, themes, scripts, config, and assets into the user's config directory so it does not depend on the clone path. It identifies Lua versus hyprlang by inspecting config contents and verifies compatibility with the installed Hyprland version. The helper emits the Lua `hl.on`/`hl.exec_cmd` startup hook for Hyprland 0.55+ and legacy hyprlang `exec-once` for earlier versions. Optional keybindings use documented Lua `hl.bind`/`hl.dsp.exec_cmd` calls or hyprlang `bind` directives. Runtime compatibility must still be confirmed in the guest. Use `--hyprland-config /absolute/path` when the active file is nonstandard but still under the selected XDG `hypr` directory, or `--no-startup` to skip integration.

## TTY and Hyprland session startup

Log in on a TTY and start Hyprland yourself; PyNix Shell does not launch the compositor at login and does not edit shell profiles. The startup hook runs inside the compositor session, independent of whether the supported command on the guest is `Hyprland`, `start-hyprland`, or `dbus-run-session Hyprland`. Executable spelling is case-sensitive. Check the actual guest using `command -v Hyprland`, `command -v start-hyprland`, and `command -v dbus-run-session`; they are alternatives, not dependencies that must all be installed.

The managed hook runs the installed launcher under the selected XDG config directory (default `~/.config/pynix-shell/scripts/start-shell.sh`), which requires the inherited Wayland display and a current-user-owned `XDG_RUNTIME_DIR`. It logs startup status at `${XDG_STATE_HOME:-~/.local/state}/pynix-shell/startup.log`, chooses the installed `qs` CLI (or `quickshell` if that is the available name), verifies its `--path`, `--no-duplicate`, and `--daemonize` options, and launches the installed `src/main.qml` by absolute installed path. It preserves the compositor's D-Bus, Wayland, runtime-directory, and Qt environment. It never starts `dbus-run-session`; an unset D-Bus address is logged as a warning and does not trigger a second bus.

Duplicate launch attempts use Quickshell's config-specific `--no-duplicate` option; no global process-name matching or restart loop is used. On uninstall, the exact unique managed block is removed from the recorded Hyprland config, preserving unrelated edits made since installation. The original config backup remains under `${XDG_STATE_HOME:-~/.local/state}/pynix-shell/backups/hyprland/`; review it before any manual whole-file restore, since that would also discard later edits.

The helper emits `hl.on("hyprland.start", ...)` with `hl.exec_cmd(...)` for Lua and uses the legacy [Hyprland 0.54 `exec-once` directive](https://wiki.hypr.land/0.54.0/Configuring/Keywords/) for hyprlang. Optional bindings use the documented [Hyprland Lua bind form](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua) or [hyprlang bind syntax](https://wiki.hypr.land/0.54.0/Configuring/Binds/). API and configuration parsing still require runtime validation in the guest.

## Shell IPC and optional key bindings

Quickshell's `IpcHandler` is registered under the `pynix` target. The documented CLI call form is `qs ipc call pynix command <command>`; use `quickshell` instead of `qs` if that is the available CLI name. For example:

```sh
qs ipc show
qs ipc call pynix command open-control-center
qs ipc call pynix command close-control-center
qs ipc call pynix command expand-island
qs ipc call pynix command collapse-island
qs ipc call pynix command open-settings
qs ipc call pynix command open-theme-switcher
qs ipc call pynix command open-launcher
```

The shell accepts only its fixed command allowlist and returns an error for unsupported names. `scripts/pynix-ipc.sh` provides the same allowlisted operations for compositor shortcuts and selects `qs` or `quickshell` without invoking a shell command string.

Keybindings are opt-in with `./install.sh --keybindings`; the standard install does not add any. After the normal separate startup-integration confirmation, the managed config block adds Super+F10 / Super+Shift+F10 for opening/closing Control Center, Super+F11 / Super+Shift+F11 for expanding/collapsing the island, Super+F9 for Settings, Super+F8 for Appearance/theme selection, and Super+F7 for the launcher. Review those keys for conflicts before choosing the option. They are stored inside the same backed-up, marker-delimited block and are removed with that block during uninstall.

## Uninstallation

```bash
./uninstall.sh
```

The uninstaller uses the same Arch, architecture, user, path, and required-tool checks. Virtualization information is optional and does not gate physical installations; detected containers are refused. It removes only manifest-listed PyNix Shell files and its exact startup block, never removes shared packages, and separately asks whether to remove `settings.json` or generated PyNix Shell backup entries. Unrecognized backup entries and non-empty unrelated directories are preserved.

## Configuration

Packaged defaults are defined in `config/defaults.json`. The runtime stores its active preference subset in the installed PyNix Shell user config directory, rather than rewriting QML or source files:

```text
~/.config/pynix-shell/settings.json
```

An absolute `XDG_CONFIG_HOME` is honored in place of `~/.config`. Persisted structured preferences cover island geometry, clock/date formatting, motion, theme, Control Center dimensions and tile layout, plus reserved launcher and notification schema fields. Theme palettes remain hard-coded in `ThemeService.qml`; the JSON theme files are not loaded by the runtime. File loading and persistence have not been runtime-tested.

## Settings application

Open Settings from the Control Center's gear button and close with its close button or Escape. The sidebar has nine sections: Bar & Island, Clock & Date, Appearance, Motion, Launcher, Notifications, Control Center, Lock Screen, and System. Search filters sections using their setting names and keywords.

Island dimensions, padding, spacing, offset, radius, artwork, status indicators, hover, clock/date formats, animation modes/durations, theme, and Control Center dimensions are bound to shared runtime settings. Compact status circles reuse the live Wi-Fi, Bluetooth, and audio services; battery percentage/state is shown only for a present, ready UPower laptop battery. Each indicator can be hidden and the order changed in Bar & Island settings. Unavailable Wi-Fi, Bluetooth, or audio is shown as an unavailable marker; absent battery hardware reserves no visible indicator. The Control Center editor operates on the live panel's persisted tile grid: compact tiles use either column, normal/large tiles span both, and occupied positions cannot overlap. Drag/right-click context menu positioning, keyboard direction buttons, context-menu resizing, tile enablement, Balanced/Compact/Media-focused presets, Tidy, Undo, and Reset all edit that shared layout.

Implemented Control Center tiles include audio, MPRIS media, theme, motion, Wi-Fi, Bluetooth, brightness, and active desktop notifications. The application launcher searches XDG desktop entries and delegates launch requests to `gtk-launch` or `gtk4-launch` when available. The lock-screen page does not inspect or alter host lock-screen configuration. Layout, Settings, launcher, and notification behavior still require graphical validation in the dedicated Arch VM.

## Network, Bluetooth, and brightness integrations

The networking and Bluetooth QML imports target the APIs documented for
Quickshell 0.3.2; actual compatibility with the guest's installed Quickshell
build still needs runtime verification. Wi-Fi uses Quickshell's
`Quickshell.Networking` API, which currently requires
NetworkManager and D-Bus. It reports the real Wi-Fi adapter/software and
hardware radio states, current SSID, connection transitions, and networks
provided by the backend. It can toggle Wi-Fi, connect/disconnect networks, and
request a PSK for supported WPA/WPA2/SAE networks. Passwords are passed only
to the Quickshell/NetworkManager connection API and are not logged or written
to PyNix settings; NetworkManager may manage a supplied secret as part of its
system connection profile. Other authentication methods are reported as
unsupported rather than simulated.

Bluetooth uses Quickshell's `Quickshell.Bluetooth` BlueZ API. It displays the
actual adapter state and connected devices and supports adapter power and
device disconnection where exposed by the API. The current API's adapter model
provides connected devices; general discovery and connecting arbitrary
unconnected devices are not offered here.

Brightness uses the optional `brightnessctl` executable for the `backlight`
device class. It reads the current/max hardware values, clamps user input,
debounces slider updates, applies changes with argument-separated process
calls, and reads back the actual result. Install `brightnessctl` on a target
system if backlight control is wanted and ensure the user has appropriate
device permissions. Desktops without a backlight or usable permissions show
an unavailable/failed state. No brightness dependency is installed by PyNix
Shell during development. While the Control Center is open, actual brightness
is re-read every five seconds to reflect external changes; slider writes are
debounced, and no brightness write is issued while the slider is idle.

## Diagnostics

The project includes a small diagnostics helper:

```bash
bash scripts/diagnose.sh
```

This prints shell health hints, config paths, and required dependency notes.
It reports which case-sensitive compositor and Quickshell command spellings are available, plus presence (not values) of relevant session environment variables.

## Source checks

These checks inspect project code and use temporary fixtures; they do not invoke the installer, uninstaller, package manager, or desktop runtime:

```bash
python3 tests/test_config.py
bash -n install.sh uninstall.sh
python3 tests/test_desktop_apps.py
bash tests/test_install_safety.sh
python3 tests/test_hyprland_startup.py
bash tests/test_start_shell.sh
```

## Limitations

The island now uses Quickshell [`PanelWindow`](https://quickshell.org/docs/v0.3.2/types/Quickshell/PanelWindow) and `Mpris`/`MprisPlayer` ([API](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Mpris/MprisPlayer)) plus PipeWire's bound default output ([API](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Pipewire/PwObjectTracker)). Source implementation does not establish successful runtime behavior: actual install/startup, rendering, control behavior, and TTY workflows remain unverified. The installer-policy correction has fixture-based and syntax checks; no installer, uninstaller, package manager, or GUI was run.

An earlier session recorded local Hyprland/Quickshell versions and command names, but those observations are not guest evidence and were not repeated during this audit. The active host config was neither read nor changed in this audit. GUI, D-Bus, rendering, no-duplicate, and each available TTY workflow remain pending until tested in the dedicated guest after explicit user request. Static checks do not establish visual or runtime correctness.

MPRIS, PipeWire, NetworkManager/Wi-Fi, BlueZ Bluetooth, optional `brightnessctl`
backlight control, XDG desktop-entry launching, and Quickshell's notification
server now have source implementations. The launcher provider may be absent,
and another notification daemon may already own the Freedesktop service name.
These integrations, like the rest of the shell, have not been runtime-tested;
API availability, permissions, real device state, and rendered controls must
be verified in the dedicated Arch VM.

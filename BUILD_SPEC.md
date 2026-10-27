# PROJECT: PYNIX SHELL

## Build a Complete, Lightweight, Feature-Rich Hyprland Desktop Shell for Arch Linux
You are the primary engineering agent responsible for designing, implementing, testing, debugging, optimizing, and documenting this project.

Operate as an expert in:

- Quickshell.
- Qt Quick and QML.
- Linux desktop-shell architecture.
- Hyprland.
- Arch Linux packaging and system integration.
- PipeWire and desktop audio.
- MPRIS media-player integration.
- NetworkManager and Bluetooth/BlueZ.
- Linux notifications.
- Qt Quick animations and graphical performance.
- Bash scripting and secure installation.
- Software testing, debugging, and maintainability.
Your assignment is to create a complete, working desktop shell called **PyNix Shell**, inspired by the Dynamic Island interface, Settings application, Control Center editor, and theme switcher demonstrated in the supplied saneAspect reference video.

This is a real implementation task.

Do not respond with a plan instead of implementing the project. Do not generate an attractive but nonfunctional mockup. Do not create a collection of files containing placeholders and declare the task completed.

Inspect the existing workspace, create the necessary project files, implement every required feature in sequence, execute the available tests, fix discovered problems, and finish the installation scripts and documentation.

**The goal is a genuinely functional desktop shell, not a screenshot recreation.**

You must preserve your progress in the repository so that implementation can resume after a context limit, interrupted session, or usage limit.

Work directly in the selected workspace. Do not ask me to manually create files that you can create yourself.

## DEVELOPMENT-HOST SAFETY AND RELEASE INSTALL SCOPE

- The current development host is not an installation or runtime test target. During development, do not run `install.sh` or `uninstall.sh`, install packages, modify host configuration/services/autostart, or activate PyNix Shell.
- Source editing and non-destructive workspace checks are permitted.
- The release installer must support Arch Linux on physical hardware and in VMs, plus compatible Arch-based distributions whose package manager and runtime dependencies are supported. The maintainer uses a dedicated Arch VM for development and GUI testing; this is not an end-user installation restriction.
- The final installer must inspect `/etc/os-release` using `ID` and `ID_LIKE`, validate architecture, pacman, the non-root intended user, safe absolute home/XDG paths, required dependencies, and explicit confirmation before changes.
- Virtualization detection is informational only. A physical system, unavailable detector, or inconclusive VM result must not cause a supported Arch installation to fail. Containers may be refused as unsupported graphical environments, but container detection must not be treated as a VM requirement.
- After explaining proposed operations and receiving consent, the installer may use standard sudo authentication for required pacman package installation and user configuration changes. It must never capture or store a sudo password, run wholesale as root, or bypass essential safety checks with Yes to All.
- After explicit consent, it may modify only one marker-delimited PyNix Shell startup block in a Hyprland config under the user's XDG config tree, after inspecting file contents, checking language/version compatibility, and backing up the original.
- The uninstaller removes only manifest-listed project files and the exact managed startup block, preserves shared packages and unrelated configuration, and separately confirms removal of settings or PyNix-owned backups.
- During project development, the maintainer performs actual install/uninstall and GUI/runtime validation only in the dedicated Arch VM and only after explicit authorization. Never test installation on the development host; this restriction does not limit end-user installation to VMs.

---

# PART I — THE PRODUCT WE ARE BUILDING

## 1. Target environment
The supported release target is Arch Linux and Arch-based distributions that
identify through `/etc/os-release` (`ID` or `ID_LIKE`) and can provide the
required dependencies through pacman. Compatibility must be checked against
the actual distribution and dependency set; do not claim support merely because
a distribution is Arch-derived.

- Package manager: pacman.
- Window manager/compositor: Hyprland.
- Shell framework: Quickshell.
- UI technology: Qt Quick/QML.
- Graphics hardware: Intel HD Graphics 2500 integrated GPU.
- Hardware class: low-end desktop with constrained graphics performance and RAM.
- Audio integration: the audio service supported by the installed environment, preferably PipeWire through supported Quickshell functionality.
- Networking integration: a supported native implementation where available, with an appropriate NetworkManager fallback.
- Media integration: MPRIS through the supported Quickshell API.
The shell must be designed for everyday use.

Do not assume that every optional hardware component is present. Brightness control, Bluetooth, battery information, and other integrations must detect their actual availability.

A missing optional capability must not prevent the entire shell from starting.

Do not present this project as compatible with arbitrary Linux distributions.

## 2. Primary objective
Create one unified shell containing:

1. A compact Dynamic Island at the top centre of the selected screen.
2. Animated compact, expanded, and contextual interface states.
3. A real media-player interface.
4. A floating Control Center.
5. Working, supported networking, Bluetooth, audio, brightness, and notification functionality.
6. A complete graphical Settings application.
7. A functional Control Center layout editor.
8. A searchable theme switcher.
9. A working application launcher.
10. A persistent configuration and theme system.
11. A consistent animation system.
12. An IPC interface and optional Hyprland key bindings.
13. Safe autostart integration.
14. A safe `./install.sh` for validated Arch-based systems using pacman.
15. A safe `./uninstall.sh`.
16. Testing, diagnostics, documentation, and performance optimization.
Every component must belong to the same cohesive system.

The Dynamic Island, Settings, Control Center, theme switcher, and launcher must share services, preferences, design tokens, and runtime state.

Do not create separate Quickshell instances merely to simplify individual components.

---

# PART II — THE REFERENCE DESIGN

## 3. Visual reference
Implement the interface according to the following observations from the supplied saneAspect video.

The reference includes:

- A small black capsule at the top centre of the screen.
- A clock and small status indicators in its compact state.
- An expanded media interface.
- Album artwork and track metadata.
- Music progress and playback controls.
- A rounded floating Control Center.
- Wi-Fi and Bluetooth controls.
- Brightness and volume sliders.
- A media tile.
- Notifications and a Clear all action.
- A graphical Settings application with a sidebar.
- A Control Center layout editor.
- A searchable, horizontally arranged theme picker.
- Smooth, coordinated transitions.
- Dark floating surfaces and restrained accent colours.
The supplied video demonstrates the song "I Ain't Worried" by OneRepublic as an example. This must NOT be hard-coded into the application. Display whatever information is provided by the real active media player.

The unnecessary final seconds of the original video do not need to be reproduced.

Do not reproduce browser windows, documentation pages, or unrelated content appearing in the recording.

Reproduce the desktop-shell features and interactions, not unrelated material shown while the creator demonstrates them.

## 4. Visual identity
The interface should feel compact, elegant, polished, and consistent.

Use:

- Capsule geometry for the Dynamic Island.
- Rounded rectangles for floating panels.
- Dark neutral surfaces as the default.
- Subtle borders.
- Restrained shadows.
- Carefully controlled transparency.
- Clear typography.
- Compact status indicators.
- A unified spacing system.
- Muted, coherent accent colours.
- Distinct focus and selection indicators.
Do not turn the design into a generic rectangular dashboard.

The Dynamic Island must remain the visual centrepiece.

Avoid excessive ornamentation. The interface should feel deliberate rather than crowded.

The desktop wallpaper should remain largely unobstructed.

Provide a coherent default dark theme, while allowing the selected theme to influence the rest of the shell appropriately.

---

# PART III — REQUIRED PROJECT MANAGEMENT

## 5. Inspect the workspace first
Before modifying files:

1. Inspect the entire relevant workspace structure.
2. Check Git status and existing changes.
3. Read existing source files and documentation.
4. Identify whether working implementation already exists.
5. Check the available Qt, QML, Quickshell, and Hyprland environment where possible.
6. Identify which tests can run in the current environment.
7. Check relevant official documentation for the installed or targeted versions.
8. Identify incompatible or outdated implementation patterns before using them.
Preserve existing work.

Do not overwrite the user's files simply because generating new ones is easier.

## 6. Create and maintain these project documents
Create these files if they do not exist:

`BUILD_SPEC.md`

- Preserve this complete specification.
- Maintain a detailed list of features and acceptance criteria.
- Keep enough information for a future session to resume without the conversation history.
`PROGRESS.md`

- Track every implementation phase.
- Track which acceptance criteria have been verified.
- Record completed tests and failures.
- Record limitations.
- Identify the exact next task.
`DECISIONS.md`

- Record important technical decisions and reasons.
- Record significant dependency and API choices.
- Explain compatibility compromises.
`README.md`

- Document installation, use, configuration, troubleshooting, and uninstallation.
- Update it as real functionality becomes available.
Do not replace useful existing documentation blindly. Merge and improve it.

Update `PROGRESS.md` after completing each major phase.

## 7. Sequential execution policy
Execute the phases of this specification in order.

For each phase:

1. Inspect the relevant code and requirements.
2. Implement the feature.
3. Run the available targeted tests.
4. Fix the errors found.
5. Verify the acceptance criteria.
6. Update the progress documentation.
7. Continue to the next phase.
Do not stop after producing a plan.

Do not stop after creating a project structure.

Do not declare success when important components are still placeholders.

If you encounter a blocker, investigate it and implement a valid fallback where possible. Continue with independent tasks rather than abandoning the entire project.

If a context or usage limit prevents completion, save all work and record the exact next implementation step in `PROGRESS.md`.

---

# PART IV — TECHNICAL ARCHITECTURE

## 8. Framework selection
Use Quickshell and QML as the primary implementation framework.

Verify every Quickshell component, import, property, enum, method, service, CLI argument, and IPC operation against the official documentation for the targeted version.

Consult current official documentation rather than assuming that APIs found in an old tutorial still work.

Prefer Quickshell's built-in integrations when they provide the necessary functionality.

Use a small external helper only when a native integration cannot provide the required capability reliably.

Do not introduce a second shell framework.

Do not create unnecessary Python daemons, browser-based interfaces, background web servers, or heavyweight application runtimes.

## 9. Project structure
Use a logical structure along these lines, adapting it to the existing repository:

```
.
├── shell.qml
├── install.sh
├── uninstall.sh
├── README.md
├── BUILD_SPEC.md
├── PROGRESS.md
├── DECISIONS.md
├── qmldir
├── components/
│   ├── DynamicIsland.qml
│   ├── IslandCompact.qml
│   ├── IslandExpanded.qml
│   ├── StatusIndicators.qml
│   ├── MediaPlayer.qml
│   ├── ControlCenter.qml
│   ├── QuickSettingsTile.qml
│   ├── BrightnessSlider.qml
│   ├── VolumeSlider.qml
│   ├── NotificationCenter.qml
│   ├── SettingsWindow.qml
│   ├── SettingsSidebar.qml
│   ├── ControlCenterEditor.qml
│   ├── ThemeSwitcher.qml
│   ├── ThemeCard.qml
│   ├── Launcher.qml
│   ├── ToggleSwitch.qml
│   └── SettingSlider.qml
├── services/
│   ├── SettingsService.qml
│   ├── ThemeService.qml
│   ├── MediaService.qml
│   ├── NetworkService.qml
│   ├── BluetoothService.qml
│   ├── AudioService.qml
│   ├── BrightnessService.qml
│   └── NotificationService.qml
├── config/
│   └── defaults.json
├── themes/
│   ├── material-you.json
│   ├── nightfox.json
│   ├── noir.json
│   ├── desert.json
│   ├── ocean.json
│   └── rose.json
├── assets/
│   └── icons/
├── scripts/
├── tests/
└── hyprland/
    └── hyprland.conf
```
This structure is a guide, not a requirement to create needless files. Every file must have a real role.

## 10. Shared state and services
Create reusable services for:

- Preferences and configuration.
- Current theme and semantic palette.
- Island state.
- Media player state.
- Control Center visibility.
- Settings visibility and active page.
- Network state.
- Bluetooth state.
- Audio volume and mute.
- Brightness where supported.
- Notifications.
- Launcher state.
- Control Center layout and editing.
The interface must have one authoritative source of truth for each category of state.

Do not independently query the same service from many widgets when a shared service can supply the state.

Do not start duplicate services when panels open.

## 11. Persistence
Use appropriate XDG-compliant configuration paths.

Separate immutable defaults shipped with the project from the user's editable preferences.

Persist:

- Selected theme.
- Supported visual preferences.
- Island geometry.
- Clock settings.
- Motion settings.
- Control Center layout.
- Launcher preferences.
- Other user-configurable settings.
Do not unnecessarily persist transient states.

Validate persisted values when loading them.

Reject malformed layout coordinates, invalid dimensions, unknown setting values, and invalid theme data.

If a configuration is malformed, recover safely and preserve a backup where appropriate.

A failed settings load must not prevent the shell from opening.

Settings should survive a shell restart and system reboot.

## 12. QML and process safety
Use supported Quickshell.Process or equivalent APIs correctly.

Pass executable arguments separately.

Do not build shell commands by concatenating user-controlled strings.

Avoid arbitrary command execution from theme files, launcher configuration, or IPC input.

Avoid synchronous work that blocks the interface thread.

Use asynchronous operations where appropriate.

Handle failures through clear error states and useful diagnostics.

---

# PART V — DESIGN SYSTEM

## 13. Semantic palette
Create a shared theme service defining:

- Main background.
- Elevated surface.
- Secondary surface.
- Primary text.
- Secondary text.
- Muted text.
- Border.
- Accent.
- Accent foreground.
- Selected state.
- Hover state.
- Success.
- Warning.
- Error.
All components must consume the same semantic palette.

Do not hard-code separate conflicting colour schemes inside individual windows.

## 14. Shared geometry
Define consistent design tokens for:

- Island width and height.
- Expanded width and height.
- Corner radius.
- Panel radius.
- Tile radius.
- Internal padding.
- Standard spacing.
- Compact spacing.
- Icon dimensions.
- Border thickness.
- Shadow intensity.
- Typography sizes.
Ensure components remain visually related.

Support practical resizing and suitable dimensions for lower-resolution screens.

## 15. Typography and icons
Use consistent typography and text hierarchy.

Use reliable SVG assets or an installed icon theme with proper fallbacks.

Avoid missing glyphs, broken image placeholders, and literal icon filenames.

Ensure controls remain distinguishable when a preferred icon is unavailable.

---

# PART VI — PRECISE ANIMATION SPECIFICATION
Animations are an essential part of the reference design.

Do not merely add animations at random. Implement a coordinated system with explicit states, sensible timing, interruption handling, and performance controls.

The timings below are starting targets. Verify the visual result where the environment permits and adjust where needed.

## 16. Animation principles
Use smooth, controlled transitions.

Initial timing targets:

- Island expansion: 180–240 ms.
- Island collapse: 140–200 ms.
- Control Center opening: 160–220 ms.
- Control Center closing: 120–180 ms.
- Settings opening: 160–220 ms.
- Settings closing: 120–180 ms.
- Theme picker opening and closing: approximately 160–220 ms and 120–180 ms.
- Hover transitions: 100–150 ms.
- Media artwork and metadata transitions: 120–180 ms.
- Editor snapping: 100–160 ms.
- Theme colour transitions: 120–200 ms.
Use suitable easing curves from the Qt Quick API supported by the selected version. Begin with smooth deceleration for opening and smooth acceleration for closing.

Do not use exaggerated bounce, elastic overshoot, unnecessarily long delays, or excessive staggered animations.

Every animation must remain interruptible.

## 17. Island expansion sequence
When the island expands:

1. Keep the island anchored to its intended top-centre position.
2. Animate width and height together.
3. Transition the corner radius and relevant internal spacing coherently.
4. Preserve the impression of a single expanding capsule.
5. Transition out compact-only content cleanly.
6. Fade expanded content in with restrained timing.
7. Optionally use a small vertical movement of approximately 4–8 logical pixels for incoming content.
8. If staggering child items, keep the delay small, approximately 20–40 ms.
9. Ensure the geometry does not jump or clip.
10. Keep the interface interactive throughout the transition.
Do not move the entire desktop or virtual screen to simulate expansion.

## 18. Island collapse sequence
When the island collapses:

1. Start from its current visual state.
2. Transition out expanded-only content.
3. Animate back to compact dimensions.
4. Restore the appropriate clock and indicators.
5. Keep the island centred.
6. Avoid horizontal drift.
7. Prevent invisible surfaces from intercepting input after closing.
8. Avoid abrupt removal of content while it is still visibly animating.

## 19. Hover and focus animations
If hover lift is enabled:

- Keep the effect subtle.
- If scaling is used, start around 1.00–1.015.
- Use approximately 100–150 ms transitions.
- Avoid continuous motion.
- Avoid repeated scaling while the pointer remains stationary.
- Provide coherent keyboard focus feedback.
- Never trigger media playback through hover alone.
- Do not make ordinary mouse movement trigger surprising expansion.

## 20. Media animations
When the track changes:

- Update actual media metadata.
- Transition the artwork and text without flashing.
- Cache artwork appropriately.
- Avoid reloading unchanged images.
- Avoid rebuilding the entire island.
- Keep the progress display current.
- Do not restart the entire expansion animation for every metadata update.
Playback controls must remain responsive.

When the media player disappears, transition to the appropriate fallback without leaving stale artwork indefinitely.

## 21. Control Center animations
When opening:

- Reveal the floating panel with coordinated opacity and restrained geometry animation.
- Keep the panel's movement subtle.
- Keep tiles visually connected.
- Avoid long, independent tile animations.
- Prevent jumps when live service data arrives.
- Do not resize the virtual desktop.
When closing:

- Animate out cleanly.
- Disable interaction once the panel is closed.
- Ensure no transparent overlay remains over other applications.

## 22. Settings animations
The Settings application should enter and leave the screen with restrained motion.

Sidebar navigation must not reconstruct the entire window.

The sidebar should remain stable while the page changes.

Use an optional short transition for content changes.

Preserve user input and unsaved layout-editor changes during normal page navigation.

Applying a setting must not wait for decorative animation to complete.

## 23. Theme picker animations
The picker must open as a wide, rounded floating panel near the top of the screen.

Its search field must become responsive immediately.

Searching must not reconstruct every card unnecessarily.

The current theme and highlighted card must remain visually distinguishable.

When a theme is applied:

- Update semantic colours through the shared theme service.
- Avoid flashes of unstyled content.
- Avoid a full-screen transition.
- Do not freeze the interface while loading a theme.
- Do not change the wallpaper unexpectedly.

## 24. Layout editor animations
While dragging or resizing:

- Update the preview responsively.
- Avoid heavy animation during every pointer event.
- Show valid drop positions.
- Prevent invalid overlapping layouts.
- Snap to legal positions on release with a restrained transition.
- Ensure Undo restores logical state rather than an invalid animated intermediate state.

## 25. Interruptions and state correctness
Users may rapidly open and close a panel, switch themes during an animation, change songs while expanded, or disconnect a system service while its tile is visible.

Handle such cases.

- Use logical state as the source of truth.
- Prevent unlimited overlapping animations.
- Reversing an animation must not cause an abrupt jump.
- Stale animation callbacks must not overwrite newer state.
- Repeated transitions must not cause continued memory growth.
- Hidden surfaces must not intercept mouse input.
- Theme changes must not reset unrelated shell state.

## 26. Reduced motion and low-performance mode
Provide independent settings for reduced motion and low-performance mode.

Reduced motion should remove unnecessary movement, hover lift, and decorative staggering.

Low-performance mode should reduce optional blur, effects, and unnecessary transitions.

Global animation disablement must not break interactions.

All modes must preserve essential functionality.

## 27. Animation tests
Test:

1. Compact to expanded island.
2. Expanded to compact island.
3. Rapid opening and closing.
4. Hover and focus.
5. Track changes during expansion.
6. Media-player disappearance.
7. Control Center opening and closing.
8. Settings opening and navigation.
9. Theme picker opening and closing.
10. Rapid theme switching.
11. Editor dragging and resizing.
12. Reduced-motion mode.
13. Low-performance mode.
14. Repeated use without memory growth.
Do not claim visual verification if the GUI was not available.

---

# PART VII — DYNAMIC ISLAND

## 28. Compact presentation
Create a small horizontal capsule centred near the top of the selected screen.

Include:

- A real clock.
- Small relevant status indicators.
- Configurable dimensions.
- Configurable top offset.
- Configurable corner radius.
- Configurable padding and spacing.
- Configurable indicator visibility and ordering.
Do not display meaningless indicators when hardware or services are unavailable.

Maintain the island's positioning when monitor configuration changes.

Avoid duplicate instances.

## 29. State machine
Implement a coherent state machine with:

- Compact.
- Expanded media.
- Expanded contextual information where applicable.
- Closing.
- Any necessary intermediate state.
Define valid state transitions and interaction triggers.

Avoid conflicting Boolean flags that permit impossible interface states.

## 30. Expanded media interface
Display:

- Album artwork.
- Track title.
- Artist.
- Playback progress.
- Previous-track control.
- Play/pause control.
- Next-track control.
- Relevant timing information where available.
Retrieve actual state from the supported MPRIS integration.

Handle multiple players and track changes appropriately.

Do not hard-code example metadata.

Handle:

- No available player.
- Missing title.
- Missing artist.
- Missing artwork.
- Incomplete metadata.
- Unsupported playback actions.
- Temporary service failure.
- Player termination.
Provide an elegant fallback state.

## 31. Configurable geometry
Support the relevant settings:

- Compact width.
- Compact height.
- Expanded width.
- Expanded height.
- Corner radius.
- Top offset.
- Internal spacing.
- Indicator visibility.
- Indicator order.
- Album-art visibility.
- Album-art sizing.
- Hover lift.
- Animation duration.
- Reduced motion.
All supported settings must affect the real interface.

### ACCEPTANCE GATE
Verify island placement, clock, compact state, expansion, collapse, media integration, fallback states, animation interruption, and settings integration.

---

# PART VIII — MEDIA SERVICE

## 32. Shared MPRIS implementation
Create one reusable media service.

Use the appropriate supported Quickshell integration.

Retrieve actual metadata, playback status, position, duration, and available actions.

Synchronise with external changes.

Ensure the island and Control Center use the same service.

Do not duplicate player connections.

Do not poll aggressively.

Do not fabricate state.

Cache artwork where appropriate.

Handle player selection and disappearance cleanly.

### ACCEPTANCE GATE
Verify media discovery, metadata changes, playback actions, progress updates, missing metadata, missing artwork, and player disconnection.

---

# PART IX — CONTROL CENTER

## 33. Floating panel
Create a compact, rounded floating panel with a dark default appearance, consistent spacing, and theme-aware styling.

It must open and close predictably.

Support an accessible keyboard shortcut through the shell IPC/Hyprland integration.

Avoid a fullscreen window unnecessarily intercepting input.

Respect screen geometry.

Reuse shared system services.

## 34. Wi-Fi integration
Prefer a supported native Quickshell networking integration where available.

Otherwise, use a safe, narrowly scoped NetworkManager integration when NetworkManager is installed.

Support available functions such as:

- Wi-Fi enabled state.
- Connection status.
- Current network name.
- Wi-Fi toggle.
- Available network discovery.
- Connection and disconnection.
Handle authentication-required networks safely.

Never log passwords.

Never assume NetworkManager is installed.

A failed operation must display an appropriate error or unavailable state.

Do not claim an operation succeeded unless the underlying system confirms it.

**Implementation status (source/API review, runtime unverified):** `NetworkService.qml`
uses Quickshell 0.3.2 `Quickshell.Networking`, whose documented backend is
NetworkManager over D-Bus. It reflects actual Wi-Fi device, hardware/software
radio, connection, SSID, and backend-provided network state; toggles Wi-Fi;
and connects/disconnects networks. Known profiles and open networks use the
native connect operation. WPA-PSK/WPA2-PSK/SAE networks can request a password
transiently; PyNix does not log or write it to its own settings, while
NetworkManager may manage the supplied secret in its system profile.
Unsupported authentication types and missing devices are shown as unavailable
or failed rather than represented as connected. Runtime permission behavior
and secret handling must be verified on the target guest.

## 35. Bluetooth integration
Use the appropriate supported Quickshell/BlueZ API.

Implement genuine:

- Bluetooth enabled state.
- Adapter availability.
- Device status.
- Connected-device information.
- Supported device-list operations.
Handle absent hardware and unavailable services gracefully.

**Implementation status (source/API review, runtime unverified):** `BluetoothService.qml`
uses Quickshell 0.3.2 `Quickshell.Bluetooth` backed by BlueZ over D-Bus. It
reads the real default adapter and connected-device model, supports adapter
power changes, and exposes connected-device disconnect operations. The
documented model used here does not provide an unconnected-device discovery
workflow, so the UI does not claim to scan or connect arbitrary new devices.

## 36. Brightness integration
Implement real brightness control using a verified supported mechanism such as `brightnessctl` or an appropriate hardware interface.

Read the current value.

Change actual brightness where supported.

Clamp values appropriately.

Handle missing permissions, unsupported hardware, and failed operations.

Some desktop PCs do not expose a controllable backlight. In such a situation, indicate that the control is unavailable rather than pretending to change brightness.

**Implementation status (source review, runtime unverified):** `BrightnessService.qml`
uses optional `brightnessctl` with argument-separated Quickshell `Process`
calls and machine-readable backlight output. It validates the device
class/current/maximum values, clamps requests, debounces slider updates, and
reads hardware state back after a write. Missing executable, unsupported
backlight, malformed output, and failed writes are surfaced as unavailable or
failed; `brightnessctl` is not installed automatically by this integration.

## 37. Audio integration
Use the supported Quickshell PipeWire integration when available.

Implement:

- Current volume.
- Volume slider.
- Mute and unmute.
- Synchronisation with external audio changes.
- Correct active state.
Do not fabricate volume levels.

Do not require installation of an unnecessary audio server.

## 38. Media tile
Implement a coherent compact media tile where appropriate.

Reuse the shared MediaService.

Keep it consistent with the expanded island player.

## 39. Notifications
Implement integration with the appropriate supported notification API.

Display real notifications with the available application name, summary, body, timestamp, and supported actions.

Provide a Clear all action and an empty state.

Handle notification overflow sensibly.

Inspect existing notification-daemon configuration.

Do not silently replace or disable dunst, mako, or any other existing notification daemon.

If a shell-owned notification server is necessary, document the integration and provide a reversible, explicit enablement option.

Do not present fabricated notification cards as live notifications.

### ACCEPTANCE GATE
Test every supported integration independently. Verify both normal operation and unavailable-service behaviour.

---

# PART X — CONTROL CENTER LAYOUT EDITOR

## 40. Editor interface
Implement the layout editor inside Settings.

**Implementation status (source/API review, runtime unverified):** the current
Settings window contains a live-synchronized editor for implemented audio,
media, appearance, motion, Wi-Fi, Bluetooth, brightness, and active-notification
tiles. Tiles can be enabled or disabled, with at least one tile required to
remain enabled. The persisted two-column grid supports compact single-column
tiles and normal/large full-width tiles, bounded row/column positioning,
overlap prevention, drag swapping, keyboard movement, and right-click resize
and position actions. The system integrations and GUI have not been
runtime-tested.

Display a preview of the actual Control Center.

Include the applicable controls:

- Wi-Fi.
- Bluetooth.
- Media.
- Brightness.
- Volume.
- Notifications.
Use a common layout model between the editor and live panel.

The preview must accurately reflect configuration.

## 41. Editing interactions
Implement:

- Drag-and-drop reordering.
- Supported control positioning.
- Resizing.
- Layout presets.
- Tidy.
- Undo.
- Reset.
Support the right-click/context-menu resizing behaviour demonstrated in the reference.

Provide an accessible alternative where practical.

Prevent illegal overlap and out-of-bounds placement.

Provide appropriate visual feedback.

## 42. Presets
Include:

- Balanced.
- Compact.
- Media-focused.
These must be real layout definitions.

Applying a preset must update the preview and live Control Center.

## 43. Tidy, Undo, Reset, persistence
Tidy must arrange supported controls coherently.

Undo must restore the previous logical state.

Reset must restore the default layout.

Persist valid arrangements.

Recover safely from corrupted or unsupported layout data.

Do not allow failed editing operations to corrupt stored settings.

### ACCEPTANCE GATE
Verify ordering, resizing, presets, Tidy, Undo, Reset, persistence, and live-layout synchronisation.

---

# PART XI — SETTINGS APPLICATION

## 44. Overall application
Build a genuine graphical Settings application.

**Implementation status (source review, not runtime validation):** all nine
required sections are registered in order in `src/SettingsWindow.qml`. Pages
for island geometry, clock/date, shared themes, motion, and Control Center
layout contain working settings. Launcher, notification, and lock-screen
pages report the absence of those integrations rather than exposing inert
controls. System reports only values available through the shell services.

It must include:

- A rounded window.
- Persistent sidebar.
- Search field.
- Main content area.
- Clear page titles.
- Appropriate scrolling.
- Reusable toggles and sliders.
- Consistent geometry and typography.
- Keyboard navigation.
- Focus states.
- Close behaviour.
- Theme integration.
Ensure the interface fits lower-resolution displays.

Do not create a Settings mockup that contains controls without working behaviour.

## 45. Sidebar sections
Implement these sections in this exact order:

1. Bar & Island
2. Clock & Date
3. Appearance
4. Motion
5. Launcher
6. Notifications
7. Control Center
8. Lock Screen
9. System
Every item must lead to a useful, functional page.

Do not make all sections display the same content.

Keep the active page highlighted.

Search must locate or filter actual settings.

## 46. Bar & Island page
Provide supported controls for:

- Compact and expanded dimensions.
- Corner radius.
- Top offset.
- Padding.
- Internal spacing.
- Status-indicator visibility and order.
- Album-art visibility and size.
- Hover lift.
- Animation settings.
- Other supported island geometry.
Apply settings to the real running shell.

Persist them.

## 47. Clock & Date page
Provide:

- Clock visibility.
- 12-hour/24-hour selection.
- Appropriate time formatting.
- Date visibility.
- Date formatting.
- Locale-aware behaviour where practical.
The actual island must use the same configuration.

## 48. Appearance page
Provide:

- Active theme.
- Theme-picker access.
- Supported accent options.
- Relevant surface and border preferences.
- Other implemented visual preferences.
Reuse the shared ThemeService.

## 49. Motion page
Provide:

- Global animations enable/disable.
- Reduced-motion mode.
- Low-performance mode.
- Island transition duration.
- Panel transition duration.
- Hover-lift toggle.
- Other supported animation options.
These must affect the actual implementation.

## 50. Launcher page
Implement a lightweight desktop application launcher.

Read installed application entries through appropriate desktop APIs or safe helpers.

Support:

- Search.
- Filtering.
- Keyboard navigation.
- Launching the selected application.
- A sensible empty state.
- Error handling.
Do not pass arbitrary desktop-entry strings to a shell as untrusted commands.

Provide relevant working settings, such as launcher width, maximum visible results, and supported appearance options.

## 51. Notifications page
Expose supported settings for notification visibility, appearance, maximum items, and relevant behaviour.

Only expose notification-history options if history is actually implemented.

## 52. Control Center page
Integrate the real layout editor, presets, appearance options, and supported tile settings.

## 53. Lock Screen page
Inspect the existing environment and installed lock-screen tooling.

Where appropriate, integrate with an existing supported tool such as hyprlock.

Provide real supported settings or safe links to the existing configuration.

Do not implement a fake password screen and call it secure.

Do not overwrite an existing lock-screen configuration automatically.

## 54. System page
Display useful system and shell information:

- Shell version.
- Quickshell version.
- Current theme.
- Configuration location.
- Availability of integrations.
- Dependency state.
- Relevant diagnostics.
Avoid unnecessary polling.

Do not expose credentials, network passwords, or sensitive data.

### ACCEPTANCE GATE
Open every section and test its actual controls, search, persistence, navigation, and interaction with the rest of the shell.

---

# PART XII — THEME SYSTEM AND SWITCHER

## 55. Theme-picker design
Implement a wide, rounded panel near the top of the screen.

It must contain:

- A search field.
- Horizontally arranged theme cards.
- Several colour swatches on each card.
- A clearly visible selected-theme outline.
- Distinct highlighted and applied states.
- Keyboard instructions.
- Appropriate horizontal scrolling.
- An empty-search state.
The panel should remain usable on a smaller display.

## 56. Required themes
Provide these built-in theme identifiers:

- `material-you`
- `nightfox`
- `noir`
- `desert`
- `ocean`
- `rose`
Each theme must provide a complete semantic palette.

Create coherent and legible palettes.

Do not falsely claim the colours exactly reproduce the video when they are not directly verified.

## 57. Theme interactions
Implement:

- Theme searching.
- Keyboard navigation.
- Mouse selection.
- Enter to apply.
- Escape to close/cancel.
- Accurate display of the active theme.
- Reliable selection handling while filtering.
Do not confuse hover state with applied state.

## 58. Real theme application
Applying a theme must change the actual appearance of:

- Dynamic Island.
- Control Center.
- Settings.
- Theme picker.
- Launcher.
- Other themed components.
Use the shared ThemeService.

Persist the selected theme.

Handle invalid files and unknown themes safely.

Do not change only the picker itself.

Do not change the desktop wallpaper without explicit, separate configuration.

### ACCEPTANCE GATE
Test all themes, search, keyboard interaction, application, persistence, and consistent appearance across every major surface.

---

# PART XIII — IPC AND HYPRLAND INTEGRATION

## 59. Shell IPC
Use Quickshell's currently supported IPC mechanism.

Implement documented operations for:

- Opening/closing Control Center.
- Expanding/collapsing the island.
- Opening/closing Settings.
- Opening/closing the theme switcher.
- Opening the launcher.
- Navigating to supported Settings pages.
- Applying a validated theme.
- Querying useful state where supported.
Validate arguments.

Handle invalid requests without crashing.

Do not expose arbitrary shell command execution.

## 60. Keyboard shortcuts
Provide documented optional Hyprland bindings for:

- Control Center.
- Dynamic Island expansion.
- Settings.
- Theme switcher.
- Launcher.
Choose sensible defaults.

Avoid common conflicts.

Keep bindings in a dedicated integration snippet.

Do not scatter modifications throughout the user's existing configuration.

Mouse interaction must also work.

## 61. Startup and monitor changes
Provide safe compositor-session startup integration. Hyprland itself is started manually from a TTY by the user; the installer must not modify login profiles or launch Hyprland.

Prevent duplicate shell instances.

Handle monitor changes and screen geometry changes.

Do not use aggressive restart loops.

Provide clear diagnostic and recovery instructions.

Support available, case-sensitive compositor launch commands such as `Hyprland`, `start-hyprland`, or `dbus-run-session Hyprland` without coupling shell startup to the wrapper command. Use the appropriate startup mechanism for the actual config format: the Lua startup event for current Lua configs and `exec-once` for compatible legacy hyprlang configs. Identify language from file contents, verify installed Hyprland compatibility, back up before edits, use one managed startup block, and remove only that block on uninstall.

The launcher must use the installed Quickshell CLI and installed QML entrypoint, wait for the compositor startup event rather than using fixed delays, validate inherited Wayland/runtime state, leave D-Bus and Qt environment variables untouched, log useful failures, and use config-specific duplicate prevention.

---

# PART XIV — INTEL HD GRAPHICS 2500 PERFORMANCE ENGINEERING

## 62. Primary performance objective
Keep the shell responsive and efficient on a low-end PC.

Do not trade everyday usability for decorative effects.

The Intel HD Graphics 2500 is an important hardware constraint.

## 63. GPU and rendering
Prefer:

- Simple Qt Quick shapes.
- Efficient opacity and geometry transitions.
- Small SVG icons.
- Restrained shadows.
- Limited transparency.
- Cached artwork.
- Small image surfaces.
- Simple borders and fills.
Avoid:

- Persistent animated backgrounds.
- Expensive shaders.
- Large blur effects.
- Multiple unnecessary off-screen layers.
- Huge animated shadows.
- Particle effects.
- Continuously animated gradients.
- Repeated full-image processing.
- Full-screen transparent input-catching surfaces.
- Unnecessary animation loops.
The interface must remain attractive with blur disabled.

## 64. CPU usage
Avoid constantly spawning commands to fetch data when event-driven updates or shared native integrations are possible.

Avoid polling loops without a clear reason.

Use the same service for data shared between components.

Reduce unnecessary updates when panels are hidden.

Do not update invisible visual elements continuously.

## 65. Memory usage
Avoid duplicate shell processes.

Reuse QML services.

Use lazy loading for expensive panels where practical.

Cache images sensibly.

Avoid unbounded notification history.

Check that repeated opening and closing does not cause memory to grow continuously.

## 66. Performance options
Provide a low-performance mode that reduces optional effects while preserving essential controls.

Reduced-motion and low-performance settings must work independently.

## 67. Measurement
When a suitable environment is available, measure or inspect:

- Idle CPU.
- Runtime memory.
- Media playback activity.
- Control Center opening/closing.
- Settings opening.
- Theme changes.
- Repeated panel interaction.
Record test methodology and actual observations.

Do not invent benchmarks.

If the exact target machine is unavailable, explicitly state that hardware-specific performance remains unverified.

---

# PART XV — ARCH LINUX INSTALLER

## 68. Create `install.sh`
The root of the project must contain an executable `./install.sh`.

This must perform a real, safe installation for the current unprivileged user on supported x86_64 Arch and Arch-based systems, whether physical or virtual. It must not be run against the development host during development.

## 69. Operating-system validation
Before modifying the guest:

1. Read `/etc/os-release`.
2. Recognize `ID` and `ID_LIKE`; require an explicitly supported Arch-compatible distribution whose required packages are available through pacman.
3. Reject unsupported distributions and do not claim compatibility solely from an Arch-derived identifier.
4. Report virtualization information when available, but do not require a positive VM result; supported physical Arch installations must be allowed by default.
5. Warn if the environment is identified as a container; do not claim container support.
6. Check the supported architecture.
7. Verify required tools.
8. Confirm a suitable user home directory.
9. Refuse installation of user configuration as root.
Do not modify the system before Arch, architecture, user-path, dependency, and confirmation checks succeed. Do not run the installer on the existing host during development.

Print useful errors and return a nonzero status on failure.

## 70. Dependency management
Determine actual required dependencies from the implementation.

Account for:

- Quickshell.
- Required Qt runtime dependencies.
- Hyprland.
- Required networking functionality.
- Required audio functionality.
- Optional brightness utilities.
- Optional Bluetooth tools.
- Required assets or icon resources.
- Appropriate testing utilities where necessary.
Verify package names and current availability using authoritative sources.

Prefer official Arch repositories.

Do not automatically install an AUR helper.

Do not install unrelated software.

Do not replace the existing audio server or notification daemon silently.

Distinguish required and optional integrations.

**Implementation status (source review; installation unverified):** the
installer checks runtime availability and configured pacman repository entries
for missing Python, Quickshell, and Hyprland packages, then requests
Y/N/Yes-to-All approval for the exact `sudo pacman -S --needed` operation.
Sudo authentication remains owned by sudo. Optional NetworkManager, BlueZ,
PipeWire, brightness, and notification components are not installed or
enabled by PyNix. Package manager behavior is covered with mocks; no actual
package operation has been run in development.

## 71. Installation safety
Explain the exact package operations and request approval. For approved required dependency installation, use pacman with standard sudo authentication. Never capture, store, or request a sudo password through custom input.

Use privileged access only for the particular package operation that needs it; never run the entire installer as root.

Provide Y, N, and A (Yes to All) choices for eligible routine operations. A must not bypass operating-system, architecture, path, dependency, user, safety, or essential confirmation checks.

Do not run an unnecessary full-system upgrade.

Do not remove existing packages automatically.

If an essential dependency cannot be installed, stop cleanly and explain how to recover.

## 72. Installation paths
Use the actual supported Quickshell configuration layout and launch syntax.

Verify the appropriate configuration-selection mechanism against current documentation.

Install under a predictable user configuration directory, without ambiguous naming.

Install necessary resources and scripts into well-defined paths.

Do not copy development-only files unnecessarily.

## 73. Backup and Hyprland integration
Before replacing any existing project-owned file:

- Detect it.
- Back it up where appropriate.
- Preserve user modifications.
- Explain the intended change.
Do not replace the user's Hyprland configuration. Ask explicitly before appending a managed startup block, inspect the actual config contents rather than relying on its suffix, make a backup, and keep rollback limited to removing that managed block.

Preserve all unrelated Hyprland configuration.

Prefer a dedicated managed configuration snippet or a clearly identifiable managed block.

Avoid duplicate entries on repeated installation.

Make integration reversible.

## 74. Post-install verification
Verify expected files and permissions.

Verify the configured launch command.

Check required dependencies.

Run available static and startup checks.

Show the exact launch command.

Explain where to find diagnostics.

Explain how to undo startup integration.

Never claim the GUI launched if it was not actually launched.

### INSTALLER ACCEPTANCE GATE
Verify unsupported-distribution rejection, validated Arch/Arch-based acceptance, physical/no-VM acceptance, non-blocking/inconclusive virtualization detection, dependency checks, sudo and consent behavior, repeatability, backup logic, exact-file ownership, configuration paths, executable permissions, and reversible integration using non-installing checks. The maintainer performs actual installation only in the dedicated Arch VM after explicit user request; end users may install on any supported physical or virtual Arch target.

---

# PART XVI — UNINSTALLER

## 75. Create `uninstall.sh`
Create an executable, safe uninstaller.

The uninstaller must fail closed unless it can confirm Arch Linux or a supported Arch-based distribution, supported architecture, safe user paths, required tools, and an unprivileged user. Virtualization detection is informational and must not reject physical Arch systems. Detected unsupported containers may be refused. Do not run it on the development host.

It must:

1. Explain what will be removed.
2. Request confirmation where appropriate.
3. Stop only the relevant shell instance.
4. Remove only project-owned files.
5. Remove only the project's managed Hyprland integration.
6. Preserve unrelated configuration.
7. Offer to preserve or remove user settings.
8. Offer to preserve or remove backups.
9. Explain how to restore the previous setup.
10. Handle partial installations.
Do not remove shared system packages automatically.

Do not delete the user's unrelated Quickshell configuration.

Do not remove existing wallpapers, themes, bars, audio settings, lock-screen configuration, or notification-daemon configuration.

Make repeated execution safe.

---

# PART XVII — AUTOMATED TESTS AND RUNTIME VALIDATION

## 76. Static checks
Create a practical test suite.

Use appropriate available tools to check:

- Bash syntax.
- ShellCheck where available.
- JSON validity.
- QML syntax and imports.
- Referenced component paths.
- Required theme keys.
- Valid setting ranges.
- Layout-data validation.
- Resource existence.
- Installation-script permissions.
- IPC documentation consistency.
If a tool is unavailable, say so.

Do not report checks as passed without running them.

## 77. Dynamic Island tests
Verify:

- Correct initial state.
- Placement.
- Clock updates.
- Expansion and collapse.
- Rapid interruption.
- Real media discovery.
- Metadata changes.
- Playback actions.
- Missing media.
- Missing artwork.
- Theme changes.
- Settings-driven geometry.
- Monitor changes where possible.

## 78. Control Center tests
Verify:

- Open/close.
- Outside interaction.
- Wi-Fi integration.
- Bluetooth integration.
- Volume integration.
- Brightness support.
- Media integration.
- Notifications.
- Clear all.
- Missing-service states.
- Persisted layout.

## 79. Settings tests
Verify every section.

Test search, navigation, toggles, sliders, theme changes, persistence, malformed configuration, reduced motion, and low-performance mode.

## 80. Layout editor tests
Test:

- Moving controls.
- Resizing.
- Layout boundaries.
- Presets.
- Tidy.
- Undo.
- Reset.
- Persistence.
- Live layout synchronisation.

## 81. Theme tests
Test all themes, search, keyboard navigation, Enter-to-apply, accurate active state, consistent palette propagation, and persistence after restart.

## 82. Installer and uninstaller tests
Safely test the preflight and ownership logic without running installation or uninstallation on the development host:

- Unsupported OS rejection.
- Root refusal.
- Missing dependencies.
- Backups.
- Repeat installation.
- Duplicate startup prevention.
- Partial installation.
- Safe uninstallation.
- Preservation of unrelated configuration.
- Continued operation when VM detection is unavailable, unknown, or reports a physical host; container support remains unvalidated.
- Config-format detection, correct Lua/hyprlang block generation, idempotency, preserving unrelated content, and removal of only the managed startup block.
- Session-variable validation and Quickshell CLI missing/unsupported behavior.
The maintainer's actual install/uninstall and GUI validation are performed in the dedicated Arch guest after explicit user request. This development test boundary does not limit end-user installation to VMs.
Do not test invalid installation paths by making destructive system changes. Do not claim the TTY launch workflows work until each available method is tested in that guest.

## 83. GUI verification
If a compatible graphical environment is available:

- Launch the shell.
- Inspect actual logs.
- Fix QML errors.
- Inspect major components.
- Verify controls and transitions.
- Check clipping and monitor geometry.
- Test repeated interactions.
- Review resource usage.
If a graphical environment is unavailable, run all relevant static tests and document the missing GUI checks.

Do not pretend headless syntax validation proves visual correctness.

---

# PART XVIII — DOCUMENTATION

## 84. Complete README
Document actual implemented functionality.

Include:

### Installation

- Supported operating system.
- Dependencies.
- Installer usage.
- Autostart setup.
- First launch.
- Verification.

### Usage

- Island interaction.
- Media controls.
- Control Center.
- Supported system controls.
- Notification interaction.
- Settings.
- Theme picker.
- Layout editing.
- Launcher.
- Keyboard shortcuts.

### Configuration

- Paths.
- Persistent settings.
- Theme definitions.
- IPC commands.
- Hyprland integration.
- Performance options.
- Optional dependencies.

### Troubleshooting

- Startup failures.
- Missing QML modules.
- Invisible panels.
- Wrong monitor placement.
- Media errors.
- Network failures.
- Bluetooth failures.
- Unsupported brightness control.
- Notification problems.
- Theme-loading errors.
- Invalid configuration.
- Duplicate instances.
- Excessive CPU or memory usage.

### Uninstallation

- Uninstaller use.
- Configuration preservation.
- Backup restoration.
- Autostart removal.
Do not document functionality that has not been implemented.

---

# PART XIX — FINAL QUALITY AUDIT

## 85. Functional audit
Verify whether all the following are actually implemented:

- Dynamic Island.
- Compact and expanded states.
- Real clock.
- Real media integration.
- Playback controls.
- Control Center.
- Supported system controls.
- Notifications.
- Settings application.
- All nine Settings sections.
- Search.
- Layout editor.
- Moving and resizing tiles.
- Presets, Tidy, Undo, and Reset.
- Theme switcher.
- All six built-in themes.
- Launcher.
- Persistent settings.
- IPC.
- Keyboard shortcuts.
- Hyprland autostart integration.
- Reduced-motion mode.
- Low-performance mode.
- Installer.
- Uninstaller.
- Tests and documentation.

## 86. Performance audit
Look for:

- Unnecessary polling.
- Duplicate services.
- Duplicate shell instances.
- Expensive effects.
- Unnecessary image decoding.
- Memory leaks or growth.
- Redundant timers.
- Excessive object creation.
- Continuous animations when idle.
- Unbounded notification history.
- Crash loops.
Fix issues that can be addressed within the project.

## 87. Reliability audit
Verify that:

- Invalid settings fail safely.
- Unsupported hardware is handled.
- Passwords are not logged.
- Existing configurations are preserved.
- Installation validation happens before modification.
- The uninstaller does not delete unrelated data.
- Failures produce useful diagnostics.
- Tests and benchmarks are reported honestly.

## 88. Visual audit
Inspect:

- Capsule geometry.
- Island placement.
- Expanded interface.
- Transition quality.
- Panel alignment.
- Control Center styling.
- Settings navigation.
- Layout editor usability.
- Theme-card presentation.
- Theme consistency.
- Small-screen clipping.
- Reduced motion.
- Low-performance rendering.
Do not declare visual fidelity verified unless an actual GUI inspection occurred.

---

# PART XX — REQUIRED COMPLETION REPORT
At the end, provide a factual report including:

1. Implemented functionality.
2. Important files created or modified.
3. Installation command.
4. Launch command.
5. Autostart setup.
6. Theme list.
7. Available integrations.
8. Tests executed.
9. Tests passed.
10. Tests failed.
11. Tests that could not run and why.
12. Performance observations and measurement conditions.
13. Known limitations.
14. Troubleshooting information.
15. Uninstallation instructions.
16. Remaining tasks, if any.
Use `PROGRESS.md` as the durable record of completion.

Do not declare the project complete if required features remain unimplemented.

---

# NON-NEGOTIABLE RULES

1. Implement real features, not mockups.
2. Do not stop at a plan.
3. Do not invent system status.
4. Do not hard-code sample media data.
5. Do not invent APIs.
6. Verify Quickshell APIs against the targeted version.
7. Do not waste GPU resources on unnecessary effects.
8. Protect existing user configuration.
9. Do not run the complete installer as root.
10. Do not silently replace other desktop components.
11. Do not leave essential settings as placeholders.
12. Do not create duplicate shell runtimes unnecessarily.
13. Do not omit the Control Center editor.
14. Do not omit the Settings application.
15. Do not omit the theme switcher.
16. Do not omit the installer or uninstaller.
17. Do not claim unrun tests passed.
18. Do not invent benchmark results.
19. Do not delete unrelated files.
20. Do not automatically install an AUR helper.
21. Do not log passwords.
22. Do not falsely claim GUI validation.
23. Do not discard progress.
24. Do not declare incomplete work finished.
25. Do not abandon independent project phases because one optional integration is unavailable.
26. Request permission for consequential operations when required.
27. Keep all changes organised and recoverable.
28. Follow the complete specification, not merely the easiest subset.

---

# FINAL EXECUTION DIRECTIVE
BEGIN IMPLEMENTATION NOW.

First, inspect the current workspace, existing code, Git status, available tools, and relevant documentation.

Create or update `BUILD_SPEC.md`, `PROGRESS.md`, `DECISIONS.md`, and `README.md`.

Then implement the complete shell sequentially through the phases defined above.

Complete the Dynamic Island, media service, Control Center, system integrations, notifications, Settings application, layout editor, theme switcher, launcher, IPC, performance optimisation, Arch-based installer, uninstaller, tests, and documentation.

After each phase, run the appropriate checks, investigate errors, correct failures, and update progress.

Do not return a plan instead of implementing the project.

Do not ask for confirmation after every ordinary coding step.

Do not ignore the performance limitations of Intel HD Graphics 2500.

Do not modify unrelated system configuration without a safe, explicit integration process.

If an operation requires permission, request it and explain its effect.

If the session or usage limit interrupts implementation, save the current work, update progress, record the exact next step, and report what remains.

Continue until the full specification has been completed to the highest level the available environment permits.

**The required result is a complete, lightweight, functional, installable Arch Linux Hyprland shell—not merely a collection of attractive QML files.**
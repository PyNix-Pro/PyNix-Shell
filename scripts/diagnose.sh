#!/usr/bin/env bash
set -u

printf 'PyNix Shell diagnostics\n'
printf 'User: %s\n' "$(id -un)"
printf 'Home: %s\n' "$HOME"
printf 'XDG_CONFIG_HOME: %s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
printf 'Project root: %s\n' "$(cd "$(dirname "$0")/.." && pwd)"

for cmd in bash python3 jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'Available: %s\n' "$cmd"
  else
    printf 'Missing: %s\n' "$cmd"
  fi
done

for cmd in Hyprland start-hyprland dbus-run-session qs quickshell; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'Session command available: %s (%s)\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'Session command unavailable: %s\n' "$cmd"
  fi
done

for variable in WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR QT_QPA_PLATFORM; do
  if printenv "$variable" >/dev/null 2>&1; then
    printf 'Session variable inherited: %s\n' "$variable"
  else
    printf 'Session variable not set: %s\n' "$variable"
  fi
done

if [ -f "$(cd "$(dirname "$0")/.." && pwd)/config/defaults.json" ]; then
  printf 'Default config: present\n'
fi

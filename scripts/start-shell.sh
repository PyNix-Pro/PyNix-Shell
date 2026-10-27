#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_CONFIG_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="${XDG_STATE_HOME:-${HOME:?HOME is required}/.local/state}/pynix-shell"
LOG_FILE="$LOG_DIR/startup.log"

log() {
  local message
  message="$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || printf 'unknown-time') $*"
  if mkdir -p -- "$LOG_DIR" 2>/dev/null && printf '%s\n' "$message" >> "$LOG_FILE" 2>/dev/null; then
    :
  else
    printf '%s\n' "$message" >&2
  fi
}

fail() {
  log "ERROR: $*"
  exit 1
}

find_quickshell_cli() {
  local config_file="$PROJECT_CONFIG_DIR/src/main.qml"
  if [[ ! -r "$config_file" ]]; then
    fail "Installed Quickshell entrypoint is missing or unreadable: $config_file"
  fi

  local candidate quickshell_cli help_text supported option
  for candidate in qs quickshell; do
    if ! command -v "$candidate" >/dev/null 2>&1; then
      continue
    fi
    quickshell_cli="$(command -v "$candidate")"
    if ! help_text="$("$quickshell_cli" --help 2>&1)"; then
      log "WARNING: could not inspect Quickshell CLI at $quickshell_cli; trying the alternate command name."
      continue
    fi
    supported=1
    for option in --path --no-duplicate --daemonize; do
      if [[ "$help_text" != *"$option"* ]]; then
        log "WARNING: Quickshell CLI $quickshell_cli lacks $option; trying the alternate command name."
        supported=0
        break
      fi
    done
    if [[ "$supported" -eq 1 ]]; then
      printf '%s\n' "$quickshell_cli"
      return 0
    fi
  done

  fail "No compatible 'qs' or 'quickshell' CLI is available in this session PATH."
}

check_runtime() {
  if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    fail "WAYLAND_DISPLAY is unset; compositor session is not ready. No environment variables were changed."
  fi
  if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -d "$XDG_RUNTIME_DIR" ]]; then
    fail "XDG_RUNTIME_DIR is unset or unavailable; cannot start Quickshell."
  fi
  if [[ "$(stat -c '%u' -- "$XDG_RUNTIME_DIR" 2>/dev/null)" != "$(id -u)" ]]; then
    fail "XDG_RUNTIME_DIR is not owned by the current user; refusing to start Quickshell."
  fi
  find_quickshell_cli
}

if [[ "${1:-}" == "--check-cli" ]]; then
  cli="$(find_quickshell_cli)" || exit $?
  printf 'Ready: %s --path %s --no-duplicate --daemonize\n' "$cli" "$PROJECT_CONFIG_DIR/src/main.qml"
  exit 0
fi
if [[ "${1:-}" == "--check" ]]; then
  cli="$(check_runtime)" || exit $?
  printf 'Ready: WAYLAND_DISPLAY, XDG_RUNTIME_DIR, and %s available.\n' "$cli"
  exit 0
fi
if [[ "$#" -ne 0 ]]; then
  printf 'Usage: %s [--check|--check-cli]\n' "$0" >&2
  exit 2
fi

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  log "D-Bus session address inherited."
else
  log "WARNING: DBUS_SESSION_BUS_ADDRESS is unset; continuing without creating a new D-Bus session."
fi
if [[ -n "${QT_QPA_PLATFORM:-}" ]]; then
  log "QT_QPA_PLATFORM inherited from compositor session."
else
  log "QT_QPA_PLATFORM is unset; allowing Qt platform auto-detection."
fi
log "Starting PyNix Shell with inherited Wayland/runtime environment; no session variables are overridden."
cli="$(check_runtime)" || exit $?
exec "$cli" --path "$PROJECT_CONFIG_DIR/src/main.qml" --no-duplicate --daemonize >> "$LOG_FILE" 2>&1

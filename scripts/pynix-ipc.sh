#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s {%s}\n' "$0" \
    "open-control-center|close-control-center|toggle-control-center|expand-island|collapse-island|toggle-island|open-settings|open-theme-switcher|open-launcher" >&2
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 2
fi

case "$1" in
  open-control-center|close-control-center|toggle-control-center|\
  expand-island|collapse-island|toggle-island|open-settings|\
  open-theme-switcher|open-launcher)
    command_name="$1"
    ;;
  *)
    printf 'Unsupported PyNix Shell command: %s\n' "$1" >&2
    usage
    exit 2
    ;;
esac

ipc_cli=""
if command -v qs >/dev/null 2>&1; then
  ipc_cli="$(command -v qs)"
elif command -v quickshell >/dev/null 2>&1; then
  ipc_cli="$(command -v quickshell)"
else
  printf 'Neither qs nor quickshell is available in PATH.\n' >&2
  exit 127
fi

exec "$ipc_cli" ipc call pynix command "$command_name"

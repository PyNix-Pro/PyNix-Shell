#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

config_dir="$tmp_dir/config"
mkdir -p "$config_dir/scripts" "$config_dir/src" "$tmp_dir/runtime" "$tmp_dir/bin"
cp "$ROOT/scripts/start-shell.sh" "$config_dir/scripts/start-shell.sh"
chmod +x "$config_dir/scripts/start-shell.sh"
touch "$config_dir/src/main.qml"

for command_name in date dirname id mkdir stat; do
  ln -s "$(command -v "$command_name")" "$tmp_dir/bin/$command_name"
done

export HOME="$tmp_dir/home"
mkdir -p "$HOME"
export XDG_STATE_HOME="$tmp_dir/state"
export XDG_RUNTIME_DIR="$tmp_dir/runtime"
chmod 700 "$XDG_RUNTIME_DIR"
log_file="$XDG_STATE_HOME/pynix-shell/startup.log"

if PATH="$tmp_dir/bin" WAYLAND_DISPLAY= /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/no-wayland.out" 2>&1; then
  printf 'Expected startup helper to reject missing WAYLAND_DISPLAY.\n' >&2
  exit 1
fi
grep -q 'WAYLAND_DISPLAY is unset' "$log_file"

if PATH="$tmp_dir/bin" WAYLAND_DISPLAY=wayland-test XDG_RUNTIME_DIR= /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/no-runtime.out" 2>&1; then
  printf 'Expected startup helper to reject missing XDG_RUNTIME_DIR.\n' >&2
  exit 1
fi
grep -q 'XDG_RUNTIME_DIR is unset or unavailable' "$log_file"

if PATH="$tmp_dir/bin" WAYLAND_DISPLAY=wayland-test XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/no-cli.out" 2>&1; then
  printf 'Expected startup helper to reject unavailable Quickshell executables.\n' >&2
  exit 1
fi
grep -q "No compatible 'qs' or 'quickshell'" "$log_file"

cat > "$tmp_dir/bin/qs" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "--help" ]]; then
  printf '%s\n' '--path --daemonize'
  exit 0
fi
EOF
chmod +x "$tmp_dir/bin/qs"
if PATH="$tmp_dir/bin" WAYLAND_DISPLAY=wayland-test XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/no-option.out" 2>&1; then
  printf 'Expected startup helper to reject an unsupported Quickshell CLI.\n' >&2
  exit 1
fi
grep -q 'lacks --no-duplicate; trying the alternate command name' "$log_file"

cat > "$tmp_dir/bin/quickshell" <<'EOF'
#!/bin/bash
printf '%s\n' '--path --no-duplicate --daemonize'
EOF
chmod +x "$tmp_dir/bin/quickshell"
PATH="$tmp_dir/bin" WAYLAND_DISPLAY=wayland-test XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/fallback-invalid-qs.out"
grep -q 'Ready: .*quickshell' "$tmp_dir/fallback-invalid-qs.out"

cat > "$tmp_dir/bin/qs" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "--help" ]]; then
  printf '%s\n' '--path --no-duplicate --daemonize'
  exit 0
fi
printf '%s\n' "$*" > "$MOCK_QS_ARGS"
printf '%s\n' "${DBUS_SESSION_BUS_ADDRESS:-unset}" > "$MOCK_QS_DBUS"
printf '%s\n' "${WAYLAND_DISPLAY:-unset}" > "$MOCK_QS_WAYLAND"
printf '%s\n' "${XDG_RUNTIME_DIR:-unset}" > "$MOCK_QS_RUNTIME"
printf '%s\n' "${QT_QPA_PLATFORM:-unset}" > "$MOCK_QS_QT"
EOF
chmod +x "$tmp_dir/bin/qs"
export MOCK_QS_ARGS="$tmp_dir/qs.args"
export MOCK_QS_DBUS="$tmp_dir/qs.dbus"
export MOCK_QS_WAYLAND="$tmp_dir/qs.wayland"
export MOCK_QS_RUNTIME="$tmp_dir/qs.runtime"
export MOCK_QS_QT="$tmp_dir/qs.qt"
export WAYLAND_DISPLAY=wayland-test
export DBUS_SESSION_BUS_ADDRESS=unix:path=/inherited/session-bus
export QT_QPA_PLATFORM=wayland
PATH="$tmp_dir/bin" /bin/bash "$config_dir/scripts/start-shell.sh"
grep -q -- "--path $config_dir/src/main.qml --no-duplicate --daemonize" "$MOCK_QS_ARGS"
grep -qF "$DBUS_SESSION_BUS_ADDRESS" "$MOCK_QS_DBUS"
grep -q '^wayland-test$' "$MOCK_QS_WAYLAND"
grep -qF "$XDG_RUNTIME_DIR" "$MOCK_QS_RUNTIME"
grep -q '^wayland$' "$MOCK_QS_QT"
grep -q 'QT_QPA_PLATFORM inherited' "$log_file"

mv "$tmp_dir/bin/qs" "$tmp_dir/bin/qs.disabled"
cat > "$tmp_dir/bin/quickshell" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "--help" ]]; then
  printf '%s\n' '--path --no-duplicate --daemonize'
  exit 0
fi
printf '%s\n' "$*" > "$MOCK_QS_ARGS"
printf '%s\n' "${DBUS_SESSION_BUS_ADDRESS:-unset}" > "$MOCK_QS_DBUS"
EOF
chmod +x "$tmp_dir/bin/quickshell"
PATH="$tmp_dir/bin" WAYLAND_DISPLAY=wayland-test XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" /bin/bash "$config_dir/scripts/start-shell.sh" --check >"$tmp_dir/fallback.out"
grep -q 'Ready: .*quickshell' "$tmp_dir/fallback.out"

unset DBUS_SESSION_BUS_ADDRESS
PATH="$tmp_dir/bin" /bin/bash "$config_dir/scripts/start-shell.sh"
grep -q '^unset$' "$MOCK_QS_DBUS"
grep -q 'continuing without creating a new D-Bus session' "$log_file"

printf 'PyNix Shell startup launcher checks passed.\n'

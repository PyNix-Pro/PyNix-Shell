#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install-safety.sh
source "$SCRIPT_DIR/scripts/install-safety.sh"

usage() {
  printf '%s\n' "Usage: $0 [--hyprland-config PATH] [--no-startup] [--keybindings]"
  printf '%s\n' "Installs PyNix Shell for the current user on supported x86_64 Arch-based Linux."
  printf '%s\n' "Startup integration is opt-in; --keybindings additionally adds reversible PyNix Shell shortcuts."
  printf '%s\n' "Missing required packages may be installed with sudo after approval; do not run this installer as root."
}

print_banner() {
  printf '%s\n' \
    ' ____        _   _ _    ____  _     _' \
    '|  _ \ _   _| \ | | |  |  _ \| |   | |' \
    '| |_) | | | |  \| | |  | |_) | |   | |' \
    '|  __/| |_| | |\  | |__|  __/| |___| |___' \
    '|_|    \__, |_| \_|_____|_|   |_____|_____|' \
    '       |___/                 P Y N I X   S H E L L'
}

require_non_root() {
  pynix_require_non_root
}

check_dependencies() {
  local required_cmds=(bash cat cp date dirname find head id mkdir mktemp mv pacman sed sort stat tr uname)
  local missing=0

  for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'Missing required command: %s\n' "$cmd" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    printf 'Install the missing basic system tools before continuing.\n' >&2
    return 1
  fi
}

install_missing_packages() {
  local package
  local -a missing=()

  for package in "$@"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      continue
    fi
    if ! pacman -Si "$package" >/dev/null 2>&1; then
      printf 'Required package %s is not installed and is unavailable in the configured pacman repositories.\n' "$package" >&2
      printf 'No package database refresh or AUR-helper installation was attempted.\n' >&2
      return 1
    fi
    missing+=("$package")
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    printf 'The required packages are missing (%s), and sudo is unavailable. Install them manually, then rerun the installer.\n' "${missing[*]}" >&2
    return 1
  fi

  printf 'Required package operation: sudo pacman -S --needed'
  printf ' %q' "${missing[@]}"
  printf '\n'
  if ! pynix_confirm_routine "Install these required packages using pacman?"; then
    printf 'Required dependency installation was declined; no user configuration was changed.\n' >&2
    return 1
  fi

  if ! sudo pacman -S --needed "${missing[@]}"; then
    printf 'pacman did not install the required packages. No user configuration has been deployed.\n' >&2
    return 1
  fi

  for package in "${missing[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
      printf 'Required package %s is still unavailable after pacman completed.\n' "$package" >&2
      return 1
    fi
  done
}

ensure_runtime_dependencies() {
  local -a packages=()

  if ! command -v python3 >/dev/null 2>&1; then
    packages+=(python)
  fi
  if ! "$SCRIPT_DIR/scripts/start-shell.sh" --check-cli >/dev/null 2>&1; then
    packages+=(quickshell)
  fi
  if ! command -v Hyprland >/dev/null 2>&1 &&
      ! command -v start-hyprland >/dev/null 2>&1 &&
      ! command -v hyprctl >/dev/null 2>&1; then
    packages+=(hyprland)
  fi

  install_missing_packages "${packages[@]}" || return 1

  if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 is still unavailable after dependency installation.\n' >&2
    return 1
  fi
  "$SCRIPT_DIR/scripts/start-shell.sh" --check-cli || return 1
  if ! command -v Hyprland >/dev/null 2>&1 &&
      ! command -v start-hyprland >/dev/null 2>&1 &&
      ! command -v hyprctl >/dev/null 2>&1; then
    printf 'Hyprland is still unavailable after dependency installation.\n' >&2
    return 1
  fi
}

ask_startup() {
  if [[ "$STARTUP_MODE" == "no" ]]; then
    return 1
  fi
  local details="Enable PyNix Shell startup in the selected Hyprland config? This edits only one managed block and backs up the original."
  if [[ "$KEYBINDINGS_MODE" == "yes" ]]; then
    details="Enable PyNix Shell startup and optional key bindings in the selected Hyprland config? This edits only one managed block and backs up the original."
  fi
  pynix_confirm_routine "$details"
}

detect_hyprland_config() {
  local helper="$SCRIPT_DIR/scripts/hyprland-startup.py"
  local args=()
  if [[ -n "$HYPRLAND_CONFIG_OVERRIDE" ]]; then
    args+=(--config "$HYPRLAND_CONFIG_OVERRIDE")
  fi

  local detected
  if ! detected="$(python3 "$helper" detect "${args[@]}")"; then
    return 1
  fi
  IFS=$'\t' read -r DETECTED_FORMAT DETECTED_CONFIG DETECTED_VERSION <<< "$detected"
  if [[ -z "$DETECTED_FORMAT" || -z "$DETECTED_CONFIG" || -z "$DETECTED_VERSION" ]]; then
    printf 'Hyprland startup integration did not return a valid configuration result.\n' >&2
    return 1
  fi
  printf 'Detected Hyprland %s config (%s) using installed version %s.\n' \
    "$DETECTED_FORMAT" "$DETECTED_CONFIG" "$DETECTED_VERSION"
}

confirm() {
  printf '%s\n' "Target: ${XDG_CONFIG_HOME:-$HOME/.config}/pynix-shell"
  printf '%s\n' "A uniquely named backup will be created if that directory already exists."
  printf '%s\n' "Missing required packages may be installed with pacman after a separate confirmation."
  printf '%s\n' "Hyprland startup integration requires separate approval."
  printf '%s\n' "Continue on this supported Arch-based system? [y/N]"
  local response
  IFS= read -r response || return 1
  [[ "$response" == "y" || "$response" == "Y" || "$response" == "yes" ]]
}

backup_existing_config() {
  local config_dir="$1"
  local backup_root="$2"
  local backup_parent="${backup_root%/*}"

  if [[ -L "$config_dir" ]]; then
    printf 'Refusing to install through a symlinked target: %s\n' "$config_dir" >&2
    return 1
  fi
  if [[ -e "$config_dir" && ! -d "$config_dir" ]]; then
    printf 'Install target exists and is not a directory: %s\n' "$config_dir" >&2
    return 1
  fi

  if [[ -d "$config_dir" ]]; then
    if [[ -L "$backup_parent" || -L "$backup_root" ]]; then
      printf 'Refusing to create a backup through a symlinked path: %s\n' "$backup_root" >&2
      return 1
    fi
    mkdir -p -- "$backup_root"
    local backup_dir
    backup_dir="$(mktemp -d "$backup_root/backup-XXXXXXXX")"
    if ! cp -a -- "$config_dir/." "$backup_dir/"; then
      printf 'Failed to back up existing configuration. Installation stopped.\n' >&2
      return 1
    fi
    printf 'pynix-shell-config-backup-v1\n' > "$backup_root/.pynix-shell-owned-${backup_dir##*/}"
    printf 'Backed up existing configuration to %s\n' "$backup_dir"
  fi
}

refuse_symlinked_app_dirs() {
  local config_dir="$1"
  local entry
  for entry in .pynix-shell-managed-files .pynix-shell-hyprland-target; do
    if [[ -L "$config_dir/$entry" ]]; then
      printf 'Refusing to replace symlinked project file: %s\n' "$config_dir/$entry" >&2
      return 1
    fi
  done

  for entry in assets config themes services src scripts; do
    if [[ -L "$config_dir/$entry" ]]; then
      printf 'Refusing to write through symlinked application directory: %s\n' "$config_dir/$entry" >&2
      return 1
    fi
    if [[ -d "$config_dir/$entry" ]]; then
      local link_path
      link_path="$(find "$config_dir/$entry" -type l -print -quit)"
      if [[ -n "$link_path" ]]; then
        printf 'Refusing to update %s because it contains symlinks. Move or review those entries first.\n' "$config_dir/$entry" >&2
        return 1
      fi
    fi
  done
}

copy_project_files() {
  local config_dir="$1"
  local manifest="$config_dir/.pynix-shell-managed-files"
  local manifest_tmp
  manifest_tmp="$(mktemp "$config_dir/.pynix-shell-manifest.XXXXXXXX")"

  local entry
  for entry in assets config themes services src scripts; do
    if [[ -d "$SCRIPT_DIR/$entry" ]]; then
      cp -a -- "$SCRIPT_DIR/$entry" "$config_dir/"
      while IFS= read -r -d '' file; do
        printf '%s\n' "${file#"$SCRIPT_DIR/"}" >> "$manifest_tmp"
      done < <(find "$SCRIPT_DIR/$entry" -type f -print0)
    fi
  done

  if [[ -f "$config_dir/.pynix-shell-hyprland-target" ]]; then
    printf '%s\n' ".pynix-shell-hyprland-target" >> "$manifest_tmp"
  fi

  if [[ -f "$manifest" ]]; then
    cat "$manifest" >> "$manifest_tmp"
  fi
  sort -u -o "$manifest_tmp" "$manifest_tmp"
  mv -f -- "$manifest_tmp" "$manifest"
  printf 'Installed PyNix Shell files under %s\n' "$config_dir"
}

write_hyprland_target_state() {
  local config_dir="$1"
  local target="$2"
  local state_file="$config_dir/.pynix-shell-hyprland-target"
  local state_tmp
  state_tmp="$(mktemp "$config_dir/.pynix-shell-target.XXXXXXXX")"
  printf '%s\n' "$target" > "$state_tmp"
  mv -f -- "$state_tmp" "$state_file"
  printf '%s\n' ".pynix-shell-hyprland-target" >> "$config_dir/.pynix-shell-managed-files"
  sort -u -o "$config_dir/.pynix-shell-managed-files" "$config_dir/.pynix-shell-managed-files"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi
  print_banner
  HYPRLAND_CONFIG_OVERRIDE=""
  STARTUP_MODE="ask"
  KEYBINDINGS_MODE="no"
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --hyprland-config)
        if [[ "$#" -lt 2 ]]; then
          printf '%s\n' "--hyprland-config requires an absolute config path." >&2
          return 2
        fi
        HYPRLAND_CONFIG_OVERRIDE="$2"
        shift 2
        ;;
      --no-startup)
        STARTUP_MODE="no"
        shift
        ;;
      --keybindings)
        KEYBINDINGS_MODE="yes"
        shift
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        return 2
        ;;
    esac
  done
  if [[ "$STARTUP_MODE" == "no" && "$KEYBINDINGS_MODE" == "yes" ]]; then
    printf '%s\n' "--keybindings requires startup integration; omit it or remove --no-startup." >&2
    return 2
  fi

  pynix_validate_arch_os /etc/os-release || return 1
  pynix_report_virtualization || return 1
  pynix_validate_architecture || return 1
  pynix_validate_user_paths || return 1
  require_non_root || return 1
  check_dependencies || return 1

  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local config_dir="$config_home/pynix-shell"
  local backup_root="$state_home/pynix-shell/backups"

  confirm || {
    printf 'Installation cancelled.\n'
    return 1
  }

  ensure_runtime_dependencies || return 1

  local enable_startup=0
  local detected_format="" detected_config="" detected_version=""
  if ask_startup; then
    detect_hyprland_config || return 1
    detected_format="$DETECTED_FORMAT"
    detected_config="$DETECTED_CONFIG"
    detected_version="$DETECTED_VERSION"
    enable_startup=1
  else
    printf 'Automatic Hyprland startup was not selected.\n'
  fi

  local target_state="$config_dir/.pynix-shell-hyprland-target"
  if [[ -L "$target_state" ]]; then
    printf 'Refusing to read a symlinked Hyprland target state file: %s\n' "$target_state" >&2
    return 1
  fi
  if [[ "$enable_startup" -eq 1 && -f "$target_state" ]]; then
    local prior_target
    IFS= read -r prior_target < "$target_state" || prior_target=""
    if [[ "$prior_target" != "$detected_config" ]]; then
      printf 'An existing managed startup entry points to %s. Remove it before changing target configs.\n' "${prior_target:-an invalid path}" >&2
      return 1
    fi
  fi

  mkdir -p -- "$config_home"
  backup_existing_config "$config_dir" "$backup_root" || return 1
  refuse_symlinked_app_dirs "$config_dir" || return 1
  mkdir -p -- "$config_dir"
  copy_project_files "$config_dir"

  if [[ "$enable_startup" -eq 1 ]]; then
    printf 'Preparing Hyprland %s startup integration for %s.\n' "$detected_format" "$detected_config"
    write_hyprland_target_state "$config_dir" "$detected_config"
    local startup_args=()
    if [[ "$KEYBINDINGS_MODE" == "yes" ]]; then
      startup_args+=(--keybindings)
    fi
    python3 "$config_dir/scripts/hyprland-startup.py" install \
      --config "$detected_config" \
      --launcher "$config_dir/scripts/start-shell.sh" \
      --backup-dir "$backup_root/hyprland" \
      "${startup_args[@]}" || return 1
  fi

  printf 'Installation complete under %s.\n' "$config_dir"
  if [[ "$enable_startup" -eq 1 ]]; then
    printf 'PyNix Shell will start inside the next Hyprland session. The current session was not activated.\n'
  else
    printf 'No Hyprland configuration was changed. Shell startup was not enabled.\n'
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

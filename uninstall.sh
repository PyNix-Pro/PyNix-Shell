#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install-safety.sh
source "$SCRIPT_DIR/scripts/install-safety.sh"

usage() {
  printf '%s\n' "Usage: $0"
  printf '%s\n' "Removes only manifest-listed PyNix Shell files on supported x86_64 Arch-based Linux."
  printf '%s\n' "It never removes shared packages or replaces Hyprland config; only its managed startup block is removed."
}

check_dependencies() {
  local required_cmds=(head id pacman python3 rm rmdir sed tr uname)
  local missing=0

  for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'Missing required command: %s\n' "$cmd" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    printf 'Required system utilities are missing; no files were removed.\n' >&2
    return 1
  fi
}

confirm() {
  printf '%s\n' "This removes only manifest-listed PyNix Shell application files."
  printf '%s\n' "User settings and backups are preserved unless separately confirmed."
  pynix_confirm "Continue with PyNix Shell uninstallation?" no yes
}

confirm_optional_removal() {
  local item="$1"
  pynix_confirm "Also remove $item?" no
}

valid_managed_path() {
  local path="$1"
  [[ "$path" != /* && "$path" != *$'\n'* && "$path" != *..* ]] || return 1
  case "$path" in
    assets/*|config/*|themes/*|services/*|src/*|hyprland/*|scripts/*|tests/*) [[ "$path" != */*/* ]] ;;
    README.md|BUILD_SPEC.md|PROGRESS.md|DECISIONS.md|.pynix-shell-hyprland-target) return 0 ;;
    *) return 1 ;;
  esac
}

remove_hyprland_integration() {
  local config_dir="$1"
  local state_file="$config_dir/.pynix-shell-hyprland-target"
  if [[ -L "$config_dir" || -L "$config_dir/scripts" ]]; then
    printf 'Refusing to read startup state through a symlinked PyNix Shell path: %s\n' "$config_dir" >&2
    return 1
  fi
  if [[ ! -e "$state_file" ]]; then
    return 0
  fi
  if [[ -L "$state_file" || ! -f "$state_file" ]]; then
    printf 'Invalid or symlinked Hyprland target state at %s; refusing removal.\n' "$state_file" >&2
    return 1
  fi

  local target state_kind="existing" generated_digest=""
  local -a state_lines=()
  mapfile -t state_lines < "$state_file"
  if [[ "${state_lines[0]:-}" == "pynix-shell-hyprland-target-v2" ]]; then
    if [[ "${#state_lines[@]}" -ne 4 ]]; then
      printf 'Invalid versioned Hyprland target state at %s; refusing removal.\n' "$state_file" >&2
      return 1
    fi
    state_kind="${state_lines[1]}"
    target="${state_lines[2]}"
    generated_digest="${state_lines[3]}"
    if [[ "$state_kind" != "existing" && "$state_kind" != "generated" ]]; then
      printf 'Invalid Hyprland config ownership state at %s; refusing removal.\n' "$state_file" >&2
      return 1
    fi
    if [[ "$state_kind" == "generated" && ! "$generated_digest" =~ ^[[:xdigit:]]{64}$ ]]; then
      printf 'Invalid generated-config fingerprint at %s; refusing removal.\n' "$state_file" >&2
      return 1
    fi
  else
    target="${state_lines[0]:-}"
  fi
  if [[ -z "$target" || "$target" == *$'\n'* ]]; then
    printf 'Invalid Hyprland target path in %s; refusing removal.\n' "$state_file" >&2
    return 1
  fi
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    printf 'Recorded Hyprland config is already absent; no config cleanup is needed: %s\n' "$target"
    return 0
  fi
  local helper="$config_dir/scripts/hyprland-startup.py"
  if [[ -L "$helper" ]]; then
    printf 'Refusing to execute a symlinked startup helper: %s\n' "$helper" >&2
    return 1
  fi
  if [[ ! -f "$helper" ]]; then
    helper="$SCRIPT_DIR/scripts/hyprland-startup.py"
  fi
  if [[ ! -f "$helper" || -L "$helper" ]]; then
    printf 'Hyprland integration helper is missing or symlinked; refusing to remove project files before cleanup.\n' >&2
    return 1
  fi
  local remove_args=(remove --config "$target")
  if [[ "$state_kind" == "generated" ]]; then
    remove_args+=(--generated-sha256 "$generated_digest")
  fi
  python3 "$helper" "${remove_args[@]}"
}

remove_managed_files() {
  local config_dir="$1"
  local manifest="$config_dir/.pynix-shell-managed-files"

  if [[ -L "$config_dir" ]]; then
    printf 'Refusing to remove files through symlinked config directory: %s\n' "$config_dir" >&2
    return 1
  fi
  if [[ -L "$manifest" ]]; then
    printf 'Refusing to read a symlinked PyNix Shell manifest: %s\n' "$manifest" >&2
    return 1
  fi
  if [[ ! -f "$manifest" ]]; then
    printf 'No PyNix Shell manifest found at %s; no application files were removed.\n' "$manifest"
    return 0
  fi

  local path dir
  local failed=0
  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -n "$path" ]] || continue
    if ! valid_managed_path "$path"; then
      printf 'Ignoring invalid manifest entry: %s\n' "$path" >&2
      failed=1
      continue
    fi
    dir="${path%%/*}"
    if [[ "$path" == */* && -L "$config_dir/$dir" ]]; then
      printf 'Refusing to traverse symlinked managed directory: %s\n' "$config_dir/$dir" >&2
      failed=1
      continue
    fi
    if [[ -f "$config_dir/$path" || -L "$config_dir/$path" ]]; then
      if ! rm -f -- "$config_dir/$path"; then
        printf 'Failed to remove managed file: %s\n' "$config_dir/$path" >&2
        failed=1
        continue
      fi
      printf 'Removed %s\n' "$config_dir/$path"
    fi
  done < "$manifest"

  if [[ "$failed" -ne 0 ]]; then
    printf 'Some manifest entries were rejected; the manifest was retained for review.\n' >&2
    return 1
  fi

  if ! rm -f -- "$manifest"; then
    printf 'Failed to remove the PyNix Shell manifest: %s\n' "$manifest" >&2
    return 1
  fi
  for dir in assets config themes services src hyprland scripts tests; do
    if [[ -d "$config_dir/$dir" && ! -L "$config_dir/$dir" ]]; then
      if ! rmdir --ignore-fail-on-non-empty -- "$config_dir/$dir"; then
        printf 'Could not remove empty application directory: %s\n' "$config_dir/$dir" >&2
        return 1
      fi
    fi
  done
  if [[ -d "$config_dir" ]]; then
    if ! rmdir --ignore-fail-on-non-empty -- "$config_dir"; then
      printf 'Could not remove empty PyNix Shell config directory: %s\n' "$config_dir" >&2
      return 1
    fi
  fi
  return "$failed"
}

remove_pynix_backups() {
  local backup_root="$1"
  local backup_dir ownership_marker hyprland_dir backup_file failed=0

  if [[ -L "${backup_root%/*}" || -L "$backup_root" ]]; then
    printf 'Refusing to remove backups through a symlinked path: %s\n' "$backup_root" >&2
    return 1
  fi
  if [[ ! -d "$backup_root" ]]; then
    return 0
  fi

  shopt -s nullglob
  for backup_dir in "$backup_root"/backup-*; do
    ownership_marker="$backup_root/.pynix-shell-owned-${backup_dir##*/}"
    if [[ -L "$backup_dir" || ! -d "$backup_dir" || -L "$ownership_marker" || ! -f "$ownership_marker" ]]; then
      printf 'Preserving unmarked, non-directory, or symlink backup entry: %s\n' "$backup_dir" >&2
      continue
    fi
    if [[ "$(head -n 1 -- "$ownership_marker")" != "pynix-shell-config-backup-v1" ]]; then
      printf 'Preserving backup directory with an unrecognized ownership marker: %s\n' "$backup_dir" >&2
      failed=1
      continue
    fi
    if rm -rf -- "$backup_dir"; then
      rm -f -- "$ownership_marker" || failed=1
    else
      failed=1
    fi
  done

  hyprland_dir="$backup_root/hyprland"
  if [[ -L "$hyprland_dir" ]]; then
    printf 'Preserving symlinked Hyprland backup directory: %s\n' "$hyprland_dir" >&2
    failed=1
  elif [[ -d "$hyprland_dir" ]]; then
    for backup_file in "$hyprland_dir"/*.pynix-*.backup; do
      if [[ -L "$backup_file" || ! -f "$backup_file" ]]; then
        printf 'Preserving non-regular Hyprland backup entry: %s\n' "$backup_file" >&2
        failed=1
        continue
      fi
      rm -f -- "$backup_file" || failed=1
    done
    rmdir --ignore-fail-on-non-empty -- "$hyprland_dir" || failed=1
  fi

  rmdir --ignore-fail-on-non-empty -- "$backup_root" || failed=1
  rmdir --ignore-fail-on-non-empty -- "${backup_root%/*}" || failed=1
  if [[ "$failed" -ne 0 ]]; then
    printf 'Some backup entries were preserved or could not be removed; review %s.\n' "$backup_root" >&2
    return 1
  fi
  printf 'Removed recognized PyNix Shell backup entries where safe; other entries were preserved.\n'
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi
  if [[ "$#" -ne 0 ]]; then
    printf 'Unknown argument: %s\n' "$1" >&2
    usage >&2
    return 2
  fi

  pynix_validate_arch_os /etc/os-release || return 1
  pynix_report_virtualization || return 1
  pynix_validate_architecture || return 1
  pynix_validate_user_paths || return 1
  check_dependencies || return 1
  pynix_require_non_root || return 1
  confirm || {
    printf 'Uninstallation cancelled.\n'
    return 1
  }

  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local config_dir="$config_home/pynix-shell"
  local backup_root="$state_home/pynix-shell/backups"

  remove_hyprland_integration "$config_dir" || return 1
  remove_managed_files "$config_dir" || return 1
  if confirm_optional_removal "PyNix Shell user settings ($config_dir/settings.json)"; then
    if [[ -L "$config_dir/settings.json" || -f "$config_dir/settings.json" ]]; then
      rm -f -- "$config_dir/settings.json"
    fi
  fi
  if confirm_optional_removal "PyNix Shell backups ($backup_root)"; then
    remove_pynix_backups "$backup_root" || return 1
  fi

  printf 'Uninstall complete. Only the managed startup block and manifest-listed app files were removed; unrelated configuration and shared packages were preserved.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

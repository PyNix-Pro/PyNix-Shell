#!/usr/bin/env bash

pynix_is_supported_arch_id() {
  local value="${1:-}"
  value="${value//\"/}"
  value="${value,,}"
  [[ "$value" == "arch" ]] || [[ "$value" == "archlinux" ]]
}

pynix_validate_arch_os() {
  local os_release="${1:-/etc/os-release}"
  if [[ ! -r "$os_release" ]]; then
    printf 'Cannot read OS release file: %s\n' "$os_release" >&2
    return 1
  fi

  local os_id="" os_id_like="" line=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      ID=*)
        os_id="${line#ID=}"
        os_id="${os_id//\"/}"
        os_id="${os_id,,}"
        ;;
      ID_LIKE=*)
        os_id_like="${line#ID_LIKE=}"
        os_id_like="${os_id_like//\"/}"
        os_id_like="${os_id_like,,}"
        ;;
    esac
  done < "$os_release"

  if pynix_is_supported_arch_id "$os_id"; then
    printf 'Validated operating system: Arch Linux (ID=%s).\n' "$os_id"
    return 0
  fi

  if [[ -n "$os_id_like" ]]; then
    local candidate
    IFS=' ' read -r -a candidates <<< "$os_id_like"
    for candidate in "${candidates[@]}"; do
      if pynix_is_supported_arch_id "$candidate"; then
        printf 'Validated operating system: Arch-compatible Linux (ID=%s, ID_LIKE=%s).\n' "${os_id:-unknown}" "$os_id_like"
        return 0
      fi
    done
  fi

  printf 'Unsupported operating system: ID=%s, ID_LIKE=%s. PyNix Shell requires Arch Linux or a compatible Arch-based distribution.\n' "${os_id:-unknown}" "${os_id_like:-unknown}" >&2
  return 1
}

pynix_report_virtualization() {
  local vm_type="" container_type="" vm_status=0 container_status=0
  if vm_type="$(systemd-detect-virt --vm 2>/dev/null)"; then
    if [[ -n "$vm_type" && "$vm_type" != "none" ]]; then
      printf 'Virtual machine detected: %s (informational).\n' "$vm_type"
    else
      printf 'No virtual machine detected; physical Arch installations are supported.\n'
    fi
  else
    vm_status=$?
    if [[ "$vm_status" -eq 1 ]]; then
      printf 'No virtual machine detected; physical Arch installations are supported.\n'
    else
      printf 'Virtualization detection failed; continuing because it is informational only.\n' >&2
    fi
  fi

  if container_type="$(systemd-detect-virt --container 2>/dev/null)"; then
    if [[ -n "$container_type" && "$container_type" != "none" ]]; then
      printf 'Unsupported container environment detected: %s. PyNix Shell requires a graphical host or VM session.\n' "$container_type" >&2
      return 1
    fi
  else
    container_status=$?
    if [[ "$container_status" -ne 1 ]]; then
      printf 'Container detection was inconclusive; proceeding with standard Arch and dependency checks.\n' >&2
    fi
  fi

  return 0
}

pynix_validate_architecture() {
  local architecture="${1:-}"
  if [[ -z "$architecture" ]] && ! architecture="$(uname -m 2>/dev/null)"; then
    printf 'Cannot determine system architecture. Refusing to continue.\n' >&2
    return 1
  fi
  if [[ "$architecture" != "x86_64" ]]; then
    printf 'Unsupported architecture: %s. PyNix Shell currently targets x86_64 Arch Linux systems.\n' "$architecture" >&2
    return 1
  fi
}

pynix_require_non_root() {
  local uid
  if ! uid="$(id -u 2>/dev/null)"; then
    printf 'Cannot determine the current user ID. Refusing to continue.\n' >&2
    return 1
  fi
  if [[ "$uid" == "0" ]]; then
    printf 'Refusing to run as root. Run this script as the intended user.\n' >&2
    return 1
  fi
}

pynix_yes_to_all=0

pynix_confirm_routine() {
  local prompt="$1"
  if [[ "$pynix_yes_to_all" -eq 1 ]]; then
    printf 'Approved by Yes to All: %s\n' "$prompt"
    return 0
  fi

  printf '%s [Y/n/a: yes to all] ' "$prompt"
  local response
  IFS= read -r response || response=""
  case "${response,,}" in
    y|yes) return 0 ;;
    a|all)
      pynix_yes_to_all=1
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

pynix_validate_user_paths() {
  if [[ -z "${HOME:-}" || "$HOME" != /* || ! -d "$HOME" || ! -w "$HOME" ]]; then
    printf 'HOME must be an existing, writable absolute directory for the intended user.\n' >&2
    return 1
  fi

  local config_home="${XDG_CONFIG_HOME:-}"
  local state_home="${XDG_STATE_HOME:-}"
  if [[ -n "$config_home" && "$config_home" != /* ]]; then
    printf 'XDG_CONFIG_HOME must be an absolute path when set. Refusing to use: %s\n' "$config_home" >&2
    return 1
  fi
  if [[ -n "$state_home" && "$state_home" != /* ]]; then
    printf 'XDG_STATE_HOME must be an absolute path when set. Refusing to use: %s\n' "$state_home" >&2
    return 1
  fi
}

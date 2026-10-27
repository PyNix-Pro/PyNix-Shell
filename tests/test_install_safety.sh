#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/install-safety.sh"
source "$ROOT/install.sh"
source "$ROOT/uninstall.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/home" "$tmp_dir/config"
printf 'ID=arch\n' > "$tmp_dir/arch-os-release"
printf 'ID=manjaro\nID_LIKE="arch"\n' > "$tmp_dir/arch-based-os-release"
printf 'ID=ubuntu\nID_LIKE="debian"\n' > "$tmp_dir/unsupported-os-release"

MOCK_VM_STATUS=none
MOCK_VM_TYPE=none
MOCK_CONTAINER_STATUS=none
MOCK_CONTAINER_TYPE=none
systemd-detect-virt() {
  case "$1" in
    --vm)
      [[ -n "$MOCK_VM_TYPE" ]] && printf '%s\n' "$MOCK_VM_TYPE"
      case "$MOCK_VM_STATUS" in
        detected) return 0 ;;
        none) return 1 ;;
        unavailable) return 127 ;;
        error) return 2 ;;
        *) return 2 ;;
      esac
      ;;
    --container)
      [[ -n "$MOCK_CONTAINER_TYPE" ]] && printf '%s\n' "$MOCK_CONTAINER_TYPE"
      case "$MOCK_CONTAINER_STATUS" in
        detected) return 0 ;;
        none) return 1 ;;
        unavailable) return 127 ;;
        error) return 2 ;;
        *) return 2 ;;
      esac
      ;;
    *) return 2 ;;
  esac
}

expect_refusal() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'Expected refusal but validation passed: %s\n' "$description" >&2
    exit 1
  fi
}

expect_refusal "unsupported distribution" pynix_validate_arch_os "$tmp_dir/unsupported-os-release"
pynix_validate_arch_os "$tmp_dir/arch-os-release" >/dev/null
pynix_validate_arch_os "$tmp_dir/arch-based-os-release" >/dev/null

MOCK_VM_STATUS=detected
MOCK_VM_TYPE=qemu
MOCK_CONTAINER_STATUS=none
output="$(pynix_report_virtualization 2>&1)"
[[ "$output" == *"Virtual machine detected: qemu"* ]]

MOCK_VM_STATUS=none
MOCK_VM_TYPE=none
output="$(pynix_report_virtualization 2>&1)"
[[ "$output" == *"physical Arch installations are supported"* ]]

MOCK_VM_STATUS=unavailable
output="$(pynix_report_virtualization 2>&1)"
[[ "$output" == *"informational only"* ]]

MOCK_VM_STATUS=error
output="$(pynix_report_virtualization 2>&1)"
[[ "$output" == *"informational only"* ]]

MOCK_VM_STATUS=detected
MOCK_VM_TYPE=qemu
MOCK_CONTAINER_STATUS=detected
MOCK_CONTAINER_TYPE=docker
expect_refusal "unsupported container environment" pynix_report_virtualization

MOCK_CONTAINER_STATUS=unavailable
MOCK_CONTAINER_TYPE=""
output="$(pynix_report_virtualization 2>&1)"
[[ "$output" == *"inconclusive"* ]]

expect_refusal "unsupported architecture" pynix_validate_architecture aarch64
pynix_validate_architecture x86_64

mock_uid=1000
id() {
  [[ "${1:-}" == "-u" ]] || return 2
  printf '%s\n' "$mock_uid"
}
mock_uid=0
expect_refusal "root execution" pynix_require_non_root
mock_uid=1000
pynix_require_non_root

empty_path="$tmp_dir/empty-path"
mkdir "$empty_path"
if output="$(PATH="$empty_path" check_dependencies 2>&1)"; then
  printf 'Expected dependency validation to fail when required tools are missing.\n' >&2
  exit 1
fi
[[ "$output" == *"Missing required command: pacman"* ]]
[[ "$output" == *"Required system utilities are missing"* ]]

banner="$(print_banner)"
[[ "$banner" == *"P Y N I X   S H E L L"* ]]

mock_installed_packages=""
mock_repository_packages="python quickshell hyprland"
mock_sudo_calls=0
pacman() {
  case "${1:-}" in
    -Q)
      [[ " $mock_installed_packages " == *" ${2:-} "* ]]
      ;;
    -Si)
      [[ " $mock_repository_packages " == *" ${2:-} "* ]]
      ;;
    -S)
      [[ "${2:-}" == "--needed" ]] || return 2
      shift 2
      mock_sudo_calls=$((mock_sudo_calls + 1))
      local requested
      for requested in "$@"; do
        mock_installed_packages+=" $requested"
      done
      ;;
    *)
      return 2
      ;;
  esac
}
sudo() {
  [[ "${1:-}" == "pacman" ]] || return 2
  shift
  pacman "$@"
}

pynix_yes_to_all=0
if install_missing_packages quickshell <<< "N" >/dev/null 2>&1; then
  printf 'Expected declined package installation to stop.\n' >&2
  exit 1
fi
[[ "$mock_sudo_calls" -eq 0 ]]

pynix_yes_to_all=0
install_missing_packages quickshell <<< "Y" >/dev/null
[[ "$mock_sudo_calls" -eq 1 ]]
[[ " $mock_installed_packages " == *" quickshell "* ]]

mock_installed_packages=""
mock_sudo_calls=0
pynix_yes_to_all=0
install_missing_packages quickshell <<< "A" >/dev/null
install_missing_packages python >/dev/null
[[ "$pynix_yes_to_all" -eq 1 ]]
[[ "$mock_sudo_calls" -eq 2 ]]
[[ " $mock_installed_packages " == *" quickshell "* ]]
[[ " $mock_installed_packages " == *" python "* ]]

mock_repository_packages="python"
if install_missing_packages hyprland <<< "Y" >/dev/null 2>&1; then
  printf 'Expected unavailable required package to stop.\n' >&2
  exit 1
fi

(
  HOME="$tmp_dir/home"
  XDG_CONFIG_HOME="$tmp_dir/config"
  XDG_STATE_HOME="$tmp_dir/state"
  export HOME XDG_CONFIG_HOME XDG_STATE_HOME
  pynix_validate_user_paths
)
if (
  HOME="$tmp_dir/home"
  XDG_CONFIG_HOME="relative-config"
  export HOME XDG_CONFIG_HOME
  pynix_validate_user_paths
) >/dev/null 2>&1; then
  printf 'Expected refusal for a relative XDG config path.\n' >&2
  exit 1
fi

pynix_yes_to_all=0
declined_action=0
if pynix_confirm_routine "decline test" <<< "N"; then
  declined_action=1
fi
[[ "$declined_action" -eq 0 ]]

pynix_yes_to_all=0
pynix_confirm_routine "approve all test" <<< "A"
[[ "$pynix_yes_to_all" -eq 1 ]]
pynix_confirm_routine "subsequent routine action"

SCRIPT_DIR="$ROOT"
install_target="$tmp_dir/config/pynix-shell"
mkdir -p "$install_target/src"
printf 'unrelated user data\n' > "$install_target/src/unrelated.txt"
copy_project_files "$install_target"
copy_project_files "$install_target"
[[ -f "$install_target/src/main.qml" ]]
[[ "$(cat "$install_target/src/unrelated.txt")" == "unrelated user data" ]]

printf 'src/main.qml\n' > "$install_target/.pynix-shell-managed-files"
remove_managed_files "$install_target"
[[ ! -e "$install_target/src/main.qml" ]]
[[ -f "$install_target/src/unrelated.txt" ]]
remove_managed_files "$install_target"
[[ -f "$install_target/src/unrelated.txt" ]]

printf 'Arch preflight, confirmation, mocked package consent/sudo, path, ownership, and repeatability checks passed.\n'

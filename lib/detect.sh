#!/usr/bin/env bash

# Shared platform detection for bootstrap stages.
# Exported values can be overridden by the caller before sourcing this file.

_dot_detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
      arch|cachyos|endeavouros|manjaro) printf 'arch\n'; return ;;
      ubuntu) printf 'ubuntu\n'; return ;;
    esac

    case " ${ID_LIKE:-} " in
      *' arch '*) printf 'arch\n'; return ;;
      *' debian '*) printf 'ubuntu\n'; return ;;
    esac
  fi

  printf 'unknown\n'
}

_dot_detect_wsl() {
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    printf '1\n'
    return
  fi

  printf '0\n'
}

_dot_detect_desktop() {
  if [ -n "${NIRI_SOCKET:-}" ] || [ "${XDG_CURRENT_DESKTOP:-}" = niri ]; then
    printf 'niri\n'
    return
  fi

  printf 'none\n'
}

_dot_detect_package_manager() {
  case "${DOT_OS:-}" in
    arch)
      if command -v paru >/dev/null 2>&1; then
        printf 'paru\n'
        return
      fi

      printf 'pacman\n'
      ;;
    ubuntu) printf 'apt\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

_dot_detect_profile() {
  if [ -n "${DOT_PROFILE:-}" ]; then
    printf '%s\n' "$DOT_PROFILE"
    return
  fi

  if [ "${DOT_WSL:-0}" = 1 ] && [ "${DOT_OS:-}" = ubuntu ]; then
    printf 'wsl-ubuntu\n'
    return
  fi

  if [ "${DOT_OS:-}" = arch ] && [ "${DOT_DESKTOP:-}" = niri ]; then
    printf 'arch-desktop\n'
    return
  fi

  if [ "${DOT_OS:-}" = arch ]; then
    printf 'arch\n'
    return
  fi

  printf 'unknown\n'
}

export DOT_OS="${DOT_OS:-$(_dot_detect_os)}"
export DOT_WSL="${DOT_WSL:-$(_dot_detect_wsl)}"
export DOT_DESKTOP="${DOT_DESKTOP:-$(_dot_detect_desktop)}"
export DOT_PACKAGE_MANAGER="${DOT_PACKAGE_MANAGER:-$(_dot_detect_package_manager)}"
export DOT_PROFILE="${DOT_PROFILE:-$(_dot_detect_profile)}"

_dot_detect_log() {
  printf 'DOT_PROFILE=%s\n' "$DOT_PROFILE"
  printf 'DOT_OS=%s\n' "$DOT_OS"
  printf 'DOT_WSL=%s\n' "$DOT_WSL"
  printf 'DOT_DESKTOP=%s\n' "$DOT_DESKTOP"
  printf 'DOT_PACKAGE_MANAGER=%s\n' "$DOT_PACKAGE_MANAGER"
}

#!/usr/bin/env bash

# Package helper functions. Source lib/detect.sh before this file.

_dot_repo_root() {
  dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
}

_dot_package_lines() {
  local file

  for file in "$@"; do
    [ -f "$file" ] || continue
    sed -E 's/[[:space:]]*#.*$//' "$file" | awk 'NF { print $1 }'
  done | sort -u
}

_dot_apt_update_once() {
  if [ -f /tmp/.dotfiles-apt-updated ] &&
    [ $(($(date +%s) - $(stat -c %Y /tmp/.dotfiles-apt-updated 2>/dev/null || echo 0))) -lt 3600 ]; then
    return
  fi

  sudo apt-get update -y
  touch /tmp/.dotfiles-apt-updated
}

install-system-packages() {
  if [ "${DOT_SKIP_PACKAGES:-0}" = 1 ]; then
    echo "[packages] DOT_SKIP_PACKAGES=1; skipping system packages"
    return
  fi

  local root
  local packages
  local files=()
  root="$(_dot_repo_root)"

  case "${DOT_PROFILE:-}" in
    arch-desktop)
      files=("$root/packages/arch" "$root/packages/arch-desktop")
      ;;
    arch)
      files=("$root/packages/arch")
      ;;
    wsl-ubuntu)
      files=("$root/packages/ubuntu" "$root/packages/wsl-ubuntu")
      ;;
    *)
      echo "[packages] Unsupported DOT_PROFILE=${DOT_PROFILE:-}" >&2
      return 1
      ;;
  esac

  packages="$(_dot_package_lines "${files[@]}")"
  [ -n "$packages" ] || return 0

  case "${DOT_PACKAGE_MANAGER:-}" in
    paru)
      printf '%s\n' "$packages" | xargs -r paru -S --needed --noconfirm --
      ;;
    pacman)
      printf '%s\n' "$packages" | xargs -r sudo pacman -S --needed --noconfirm --
      ;;
    apt)
      _dot_apt_update_once
      printf '%s\n' "$packages" | xargs -r sudo apt-get install -y
      ;;
    *)
      echo "[packages] Unknown DOT_PACKAGE_MANAGER=${DOT_PACKAGE_MANAGER:-}" >&2
      return 1
      ;;
  esac
}

update-system-packages() {
  if [ "${DOT_SKIP_PACKAGES:-0}" = 1 ]; then
    echo "[packages] DOT_SKIP_PACKAGES=1; skipping system update"
    return
  fi

  case "${DOT_PACKAGE_MANAGER:-}" in
    paru) paru -Syu --noconfirm ;;
    pacman) sudo pacman -Syu --noconfirm ;;
    apt)
      sudo apt-get update -y
      sudo apt-get upgrade -y
      ;;
    *)
      echo "[packages] Unsupported DOT_PACKAGE_MANAGER=${DOT_PACKAGE_MANAGER:-}" >&2
      return 1
      ;;
  esac
}

install-aur-packages() {
  if [ "${DOT_SKIP_PACKAGES:-0}" = 1 ]; then
    echo "[packages] DOT_SKIP_PACKAGES=1; skipping AUR packages"
    return
  fi

  [ "${DOT_PACKAGE_MANAGER:-}" = paru ] || return 0

  local root
  local packages
  root="$(_dot_repo_root)"

  case "${DOT_PROFILE:-}" in
    arch-desktop) packages="$(_dot_package_lines "$root/packages/arch-aur" "$root/packages/arch-desktop-aur")" ;;
    arch) packages="$(_dot_package_lines "$root/packages/arch-aur")" ;;
    *) return 0 ;;
  esac

  [ -n "$packages" ] || return 0
  printf '%s\n' "$packages" | xargs -r paru -S --needed --noconfirm
}

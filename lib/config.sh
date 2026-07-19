#!/usr/bin/env bash

# Reconcile managed dotfiles, scripts, and generated shell completions.

_dot_config_root() {
  dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
}

_config_log() {
  printf '\033[1;36m[config]\033[0m %s\n' "$*"
}

_link_path() {
  local source="$1"
  local target="$2"
  local name="$3"
  local backup

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(realpath "$source")" ]; then
    _config_log "$name already linked correctly"
    CONFIG_SKIPPED=$((CONFIG_SKIPPED + 1))
    return
  fi

  if [ -e "$target" ] && [ ! -L "$target" ] && [ "${DOTFILES_REPLACE_DIRS:-0}" != 1 ]; then
    _config_log "Skipping $name; target already exists: $target"
    _config_log "Set DOTFILES_REPLACE_DIRS=1 to back it up and link the repo version"
    CONFIG_SKIPPED=$((CONFIG_SKIPPED + 1))
    return
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    _config_log "Backing up existing $name to $backup"
    mv -- "$target" "$backup"
  fi

  _config_log "Linking $name"
  mkdir -p "$(dirname "$target")"
  ln -sfnT -- "$(realpath "$source")" "$target"
  CONFIG_LINKED=$((CONFIG_LINKED + 1))
}

_migrate_legacy_dotfile() {
  local source="$1"
  local target="$2"
  local name="$3"
  local root="$4"
  local managed=0
  local backup

  if [ ! -d "$target" ] || [ -L "$target" ]; then
    return
  fi

  case "$name" in
    mise)
      [ -L "$target/config.toml" ] &&
        [ "$(readlink -f "$target/config.toml")" = "$(realpath "$source/config.toml")" ] &&
        managed=1
      ;;
    zsh)
      [ -L "$target/.zshrc" ] && [ "$(readlink "$target/.zshrc")" = "$root/.zshrc" ] &&
        managed=1
      ;;
  esac

  [ "$managed" = 1 ] || return 0
  backup="$target.backup.$(date +%Y%m%d%H%M%S)"
  _config_log "Migrating legacy managed $name directory to $backup"
  mv -- "$target" "$backup"
}

apply-dotfiles() {
  local component="${1:-}"
  local root
  local managed
  local legacy
  local config
  local dot
  local name
  local target
  local source

  root="$(_dot_config_root)"
  managed="$root/config"
  legacy="$root/dotfiles"
  config="${XDG_CONFIG_HOME:-$HOME/.config}"

  if [ -n "$component" ] && [ ! -e "$managed/$component" ]; then
    echo "[config] Unknown component: $component" >&2
    return 1
  fi

  mkdir -p "$config"
  _config_log "Linking ${component:-all dotfiles} for ${DOT_PROFILE:-unknown}"
  CONFIG_LINKED=0
  CONFIG_SKIPPED=0
  CONFIG_REMOVED=0

  shopt -s nullglob dotglob
  for dot in "$managed"/*; do
    [ -f "$dot" ] || [ -d "$dot" ] || continue
    name="$(basename "$dot")"
    [ -z "$component" ] || [ "$name" = "$component" ] || continue

    case "$name" in
      ghostty | niri | noctalia | rofi | environment.d)
        [ "${DOT_PROFILE:-}" = arch-desktop ] || continue
        ;;
    esac

    target="$config/$name"
    [ "$name" != .tmux.conf ] || target="$HOME/$name"

    _migrate_legacy_dotfile "$dot" "$target" "$name" "$root"
    _link_path "$dot" "$target" "$name"
    [ "$name" != zsh ] || _link_path "$dot/.zshenv" "$HOME/.zshenv" .zshenv
  done

  if [ -z "$component" ]; then
    for target in "$config"/*; do
      [ -L "$target" ] || continue
      source="$(readlink "$target")"

      case "$source" in
        "$managed"/* | "$legacy"/*)
          [ -e "$target" ] && continue
          _config_log "Removing obsolete managed dotfile $(basename "$target")"
          rm -- "$target"
          CONFIG_REMOVED=$((CONFIG_REMOVED + 1))
          ;;
      esac
    done
  fi

  _config_log "Dotfiles: linked $CONFIG_LINKED, skipped $CONFIG_SKIPPED, removed $CONFIG_REMOVED"
}

link-scripts() {
  local root
  local scripts
  local bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
  local script
  local name
  local target
  local source

  root="$(_dot_config_root)"
  scripts="$(realpath "$root/scripts")"
  mkdir -p "$bin"
  CONFIG_LINKED=0
  CONFIG_SKIPPED=0
  CONFIG_REMOVED=0

  for script in "$scripts"/*; do
    [ -f "$script" ] || continue
    name="$(basename "$script")"
    target="$bin/$name"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$script" ]; then
      CONFIG_SKIPPED=$((CONFIG_SKIPPED + 1))
      continue
    fi

    _config_log "Linking script $name"
    ln -sfn -- "$(realpath "$script")" "$target"
    CONFIG_LINKED=$((CONFIG_LINKED + 1))
  done

  for target in "$bin"/*; do
    [ -L "$target" ] || continue
    source="$(readlink "$target")"

    case "$source" in
      "$scripts"/*)
        [ -e "$target" ] && continue
        _config_log "Removing obsolete managed script $(basename "$target")"
        rm -- "$target"
        CONFIG_REMOVED=$((CONFIG_REMOVED + 1))
        ;;
    esac
  done

  _config_log "Scripts: linked $CONFIG_LINKED, skipped $CONFIG_SKIPPED, removed $CONFIG_REMOVED"
}

_generate_completion() {
  local dest="$1"
  local name="$2"
  shift 2
  local target="$dest/$name"
  local tmp="$target.$$"

  command -v "$1" >/dev/null 2>&1 || return 0

  if "$@" >"$tmp" && [ -s "$tmp" ]; then
    chmod 644 "$tmp"
    mv -- "$tmp" "$target"
    _config_log "Generated completion $name"
    return
  fi

  rm -f -- "$tmp"
  echo "[config] Failed to generate completion $name" >&2
  return 1
}

generate-completions() {
  local dest="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  local shims="${MISE_SHIMS:-$HOME/.local/share/mise/shims}"

  if [ -d "$shims" ] && [[ ":$PATH:" != *":$shims:"* ]]; then
    export PATH="$shims:$PATH"
  fi

  mkdir -p "$dest"
  _generate_completion "$dest" _mise mise completion zsh
  _generate_completion "$dest" _just just --completions zsh
  _generate_completion "$dest" _gh gh completion -s zsh
  _generate_completion "$dest" _jj jj util completion zsh
  _generate_completion "$dest" _niri niri completions zsh
  rm -f -- "$cache/compdump" "$cache/compdump.zwc"
}

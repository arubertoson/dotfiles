#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
HOME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-apply-smoke.XXXXXX")"
CONFIG="$HOME_DIR/.config"
BIN="$HOME_DIR/.local/bin"
FORBIDDEN_LOG="$HOME_DIR/forbidden.log"
APPLY_LOG="$HOME_DIR/apply.log"
STUBS="$HOME_DIR/stubs"

cleanup() {
  rm -rf -- "$HOME_DIR"
}
trap cleanup EXIT

fail() {
  printf '[apply-smoke] FAIL: %s\n' "$*" >&2
  exit 1
}

assert-link() {
  local target="$1"
  local source="$2"

  [ -L "$target" ] || fail "$target is not a symbolic link"
  [ "$(readlink -f "$target")" = "$(realpath "$source")" ] || \
    fail "$target does not point to $source"
}

run-apply() {
  if env -i \
    HOME="$HOME_DIR" \
    USER="${USER:-dotfiles-smoke}" \
    LOGNAME="${LOGNAME:-${USER:-dotfiles-smoke}}" \
    SHELL="/bin/bash" \
    TERM="dumb" \
    PATH="$STUBS:/usr/bin:/bin" \
    TMPDIR="$HOME_DIR/tmp" \
    XDG_CONFIG_HOME="$CONFIG" \
    XDG_CACHE_HOME="$HOME_DIR/.cache" \
    XDG_DATA_HOME="$HOME_DIR/.local/share" \
    XDG_STATE_HOME="$HOME_DIR/.local/state" \
    XDG_BIN_HOME="$BIN" \
    XDG_APP_HOME="$HOME_DIR/.local/package" \
    XDG_DEV_HOME="$HOME_DIR/dev" \
    MISE_CONFIG_DIR="$CONFIG/mise" \
    MISE_DATA_DIR="$HOME_DIR/.local/share/mise" \
    MISE_CACHE_DIR="$HOME_DIR/.cache/mise" \
    MISE_STATE_DIR="$HOME_DIR/.local/state/mise" \
    DOT_PROFILE="arch" \
    DOT_OS="arch" \
    DOT_WSL="0" \
    DOT_DESKTOP="none" \
    DOT_PACKAGE_MANAGER="pacman" \
    SMOKE_FORBIDDEN_LOG="$FORBIDDEN_LOG" \
    "$ROOT/bootstrap" apply > "$APPLY_LOG" 2>&1; then
    return
  fi

  cat "$APPLY_LOG" >&2
  fail "bootstrap apply failed"
}

mkdir -p "$STUBS" "$HOME_DIR/tmp" "$CONFIG"
ln -s "$ROOT/dotfiles/zsh" "$CONFIG/zsh"
ln -s "$ROOT/dotfiles/zsh/.zshenv" "$HOME_DIR/.zshenv"

cat > "$STUBS/forbidden" <<'EOF'
#!/bin/sh
printf '%s\n' "$(basename "$0") $*" >> "${SMOKE_FORBIDDEN_LOG:?}"
exit 97
EOF
chmod +x "$STUBS/forbidden"

for command in sudo pacman paru apt-get curl wget git ssh scp bun uvx; do
  ln -s forbidden "$STUBS/$command"
done

run-apply

assert-link "$CONFIG/zsh" "$ROOT/config/zsh"
assert-link "$HOME_DIR/.zshenv" "$ROOT/config/zsh/.zshenv"
assert-link "$CONFIG/git" "$ROOT/config/git"
assert-link "$CONFIG/mise" "$ROOT/config/mise"
assert-link "$HOME_DIR/.tmux.conf" "$ROOT/config/.tmux.conf"
assert-link "$BIN/dev-workspace" "$ROOT/scripts/dev-workspace"

[ ! -e "$CONFIG/niri" ] || fail "desktop dotfiles were linked for the arch profile"
[ ! -e "$CONFIG/ghostty" ] || fail "desktop dotfiles were linked for the arch profile"

# A managed link that drifts must be repaired on the next reconciliation.
ln -sfnT "$HOME_DIR/missing-zsh" "$CONFIG/zsh"
run-apply
assert-link "$CONFIG/zsh" "$ROOT/config/zsh"

# Existing unmanaged paths must never be replaced without explicit adoption.
rm -- "$CONFIG/git"
mkdir -p "$CONFIG/git"
printf 'keep\n' > "$CONFIG/git/unmanaged"
run-apply
[ ! -L "$CONFIG/git" ] || fail "an unmanaged config directory was replaced"
[ "$(<"$CONFIG/git/unmanaged")" = keep ] || fail "an unmanaged file was changed"

# Cleanup is restricted to obsolete links that previously pointed into this repository.
ln -s "$ROOT/dotfiles/removed-component" "$CONFIG/removed-component"
ln -s "$ROOT/scripts/removed-command" "$BIN/removed-command"
ln -s "$HOME_DIR/unrelated-missing" "$CONFIG/unrelated-broken"
run-apply

[ ! -L "$CONFIG/removed-component" ] || fail "an obsolete managed dotfile link remains"
[ ! -L "$BIN/removed-command" ] || fail "an obsolete managed script link remains"
[ -L "$CONFIG/unrelated-broken" ] || fail "an unrelated broken link was removed"

run-apply

[ ! -s "$FORBIDDEN_LOG" ] || \
  fail "apply invoked a forbidden command: $(tr '\n' ' ' < "$FORBIDDEN_LOG")"

if find "$HOME_DIR" -name '*.backup.*' -print -quit | grep -q .; then
  fail "apply unexpectedly created a backup"
fi

printf '[apply-smoke] OK\n'

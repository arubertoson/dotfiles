#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workspace-picker.XXXXXX")"
REAL_FZF="$(command -v fzf || true)"
export REAL_FZF
trap 'rm -rf -- "$TEMP"' EXIT

fail() {
  printf '[workspace-picker] FAIL: %s\n' "$*" >&2
  exit 1
}

export HOME="$TEMP/home"
export DEV_WORKSPACE_DEV_ROOT="$HOME/dev"
export DEV_WORKSPACE_CACHE_DIR="$TEMP/cache"
export DEV_WORKSPACE_BACKEND=tmux
export DEV_WORKSPACE_CACHE_TTL=900
export DEV_WORKSPACE_PROJECT_MAX_DEPTH=6
export DEV_WORKSPACE_FZF_DEFAULT_OPTS=''
unset DEV_WORKSPACE_FZF_HEIGHT FZF_DEFAULT_OPTS
export MISE_SHIMS="$TEMP/no-shims"
mkdir -p "$TEMP/bin" \
  "$DEV_WORKSPACE_DEV_ROOT/home/github.com/alpha/shared/.git" \
  "$DEV_WORKSPACE_DEV_ROOT/home/github.com/beta/shared/.git" \
  "$DEV_WORKSPACE_DEV_ROOT/work/codeberg.org/team/Alpha project/.git" \
  "$DEV_WORKSPACE_DEV_ROOT/solo/.git"

# Load the same configuration and entry points as the executable, without opening a session.
source "$ROOT/scripts/dev-workspace" help >/dev/null

raw="$("$ROOT/scripts/dev-workspace" list-projects --refresh)"
[[ "$(wc -l <<<"$raw")" == 4 ]] || fail 'repository discovery changed'
[[ "$raw" == *$'git\t~dev/home/github.com/alpha/shared\t'* ]] ||
  fail 'the canonical TSV interface changed'

compact="$("$ROOT/scripts/dev-workspace" list-projects --compact)"
expected="$(printf 'Alpha project\twork/codeberg.org/team\t%s\nshared       \tgithub.com/alpha\t%s\nshared       \tgithub.com/beta\t%s\nsolo         \t~dev\t%s' \
  "$DEV_ROOT/work/codeberg.org/team/Alpha project" \
  "$DEV_ROOT/home/github.com/alpha/shared" \
  "$DEV_ROOT/home/github.com/beta/shared" \
  "$DEV_ROOT/solo")"
[[ "$compact" == "$expected" ]] || fail 'compact names, contexts, sorting, or paths are wrong'

cat >"$TEMP/bin/rofi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$PICKER_ARGS"
input="$(cat)"
if [[ "$ROFI_ACTION" == cancel ]]; then
  exit 1
fi
if [[ "$ROFI_ACTION" == refresh && ! -f "$REFRESH_MARKER" ]]; then
  mkdir -p "$PICKER_TARGET/.git"
  touch "$REFRESH_MARKER"
  exit 10
fi
awk -F '\t' -v target="$PICKER_TARGET" '$3 == target' <<<"$input"
EOF
chmod +x "$TEMP/bin/rofi"
export PATH="$TEMP/bin:$PATH"
export DEV_WORKSPACE_PICKER=rofi
export PICKER_ARGS="$TEMP/args"
export PICKER_TARGET="$DEV_ROOT/work/codeberg.org/team/Alpha project"
export ROFI_ACTION=select
[[ "$(pick-project-path)" == "$PICKER_TARGET" ]] || fail 'rofi lost the path containing spaces'
grep -Fxq -- '-display-columns' "$PICKER_ARGS" || fail 'rofi displays the hidden path'
grep -Fxq -- '-no-custom' "$PICKER_ARGS" || fail 'rofi allows non-project entries'

export ROFI_ACTION=cancel
[[ -z "$(pick-project-path)" ]] || fail 'rofi cancellation selected a project'

export ROFI_ACTION=refresh
export REFRESH_MARKER="$TEMP/refreshed"
export PICKER_TARGET="$DEV_ROOT/home/github.com/new/new project"
[[ "$(pick-project-path)" == "$PICKER_TARGET" ]] || fail 'rofi refresh did not discover the new project'

if [[ -n "$REAL_FZF" ]]; then
  cat >"$TEMP/bin/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$PICKER_ARGS"
exec "$REAL_FZF" "$@" --filter="$PICKER_QUERY"
EOF
  chmod +x "$TEMP/bin/fzf"
  export DEV_WORKSPACE_PICKER=fzf
  export PICKER_QUERY='shared beta'
  [[ "$(pick-project-path)" == "$DEV_ROOT/home/github.com/beta/shared" ]] ||
    fail 'fzf did not disambiguate duplicate names by location'
  grep -Fxq -- '--with-nth=1,2' "$PICKER_ARGS" || fail 'fzf displays the hidden path'
  grep -Fxq -- '--height=~20' "$PICKER_ARGS" || fail 'fzf is not bounded in height'
  grep -Fxq -- 'ctrl-r:reload(dev-workspace list-projects --compact --refresh)+clear-query' "$PICKER_ARGS" ||
    fail 'fzf refresh uses a different record format'
  export PICKER_QUERY='Alpha project'
  [[ "$(pick-project-path)" == "$DEV_ROOT/work/codeberg.org/team/Alpha project" ]] ||
    fail 'fzf lost the path containing spaces'
  export PICKER_QUERY='no-such-project'
  [[ -z "$(pick-project-path)" ]] || fail 'an empty fzf result selected a project'
fi

printf '[workspace-picker] OK\n'
if [[ -z "$REAL_FZF" ]]; then
  printf '[workspace-picker] SKIP: fzf checks (fzf not installed)\n'
fi

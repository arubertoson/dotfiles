#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workspace-clipboard.XXXXXX")"
trap 'tmux -S "$TEMP/tmux" kill-server 2>/dev/null || true; rm -rf -- "$TEMP"' EXIT

# Use an isolated real server; no terminal clipboard is touched by this test.
tmux -S "$TEMP/tmux" -f /dev/null new-session -d -s clipboard
export TMUX="$TEMP/tmux,$(tmux -S "$TEMP/tmux" display-message -p '#{pid}'),0"
export MISE_SHIMS="$TEMP/no-shims"

VALUE='/tmp/project with spaces/日本語'
"$ROOT/scripts/dev-workspace" yank-path "$VALUE"
[[ "$(tmux -S "$TEMP/tmux" show-buffer)" == "$VALUE" ]] || {
  printf '[workspace-clipboard] clipboard buffer lost the path\n' >&2
  exit 1
}

# A leading dash must be treated as text, not a tmux option.
"$ROOT/scripts/dev-workspace" yank-path '-project'
[[ "$(tmux -S "$TEMP/tmux" show-buffer)" == '-project' ]]

printf '[workspace-clipboard] passed\n'

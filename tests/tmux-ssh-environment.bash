#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tmux-ssh.XXXXXX")"
trap 'tmux -S "$TEMP/tmux" kill-server 2>/dev/null || true; rm -rf -- "$TEMP"' EXIT

tmux -S "$TEMP/tmux" -f /dev/null new-session -d -s clipboard
export TMUX="$TEMP/tmux,$(tmux -S "$TEMP/tmux" display-message -p '#{pid}'),0"
unset TMUX_PANE

zsh -f -s -- "$ROOT" <<'EOF'
set -euo pipefail

fail() {
  print -u2 -- "[tmux-ssh-environment] FAIL: $*"
  exit 1
}

source "$1/config/zsh/rc.d/04-tmux.zsh"
source "$1/config/zsh/rc.d/04-tmux.zsh"
(( ${#precmd_functions} == 1 )) || fail 'sourcing twice registered duplicate hooks'

prompt() {
  local hook
  for hook in "${precmd_functions[@]}"; do
    "$hook"
  done
}

export SSH_CONNECTION='stale local environment'
tmux set-environment SSH_CONNECTION '192.0.2.1 12345 192.0.2.2 22'
prompt
[[ "$SSH_CONNECTION" == '192.0.2.1 12345 192.0.2.2 22' ]] || fail 'existing pane did not inherit SSH connection'
[[ "$(sh -c 'printf %s "$SSH_CONNECTION"')" == "$SSH_CONNECTION" ]] || fail 'connection was not exported to child processes'

tmux set-environment SSH_CONNECTION '192.0.2.3 54321 192.0.2.2 22'
prompt
[[ "$SSH_CONNECTION" == '192.0.2.3 54321 192.0.2.2 22' ]] || fail 'reattaching did not refresh SSH connection'

tmux set-environment -r SSH_CONNECTION
prompt
[[ -z "${SSH_CONNECTION+x}" ]] || fail 'local attachment retained stale SSH connection'

tmux set-environment -u SSH_CONNECTION
export SSH_CONNECTION='preserved when lookup fails'
prompt
[[ "$SSH_CONNECTION" == 'preserved when lookup fails' ]] || fail 'failed lookup erased inherited environment'

unset TMUX
prompt
[[ "$SSH_CONNECTION" == 'preserved when lookup fails' ]] || fail 'non-tmux shell changed SSH connection'
EOF

printf '[tmux-ssh-environment] OK\n'

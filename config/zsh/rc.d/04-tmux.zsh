#!/bin/zsh

# Existing panes keep their original environment when a new SSH client attaches.
tmux-sync-ssh() {
  [[ -n "${TMUX:-}" ]] || return 0

  local connection
  connection="$(tmux show-environment SSH_CONNECTION 2>/dev/null)" || return 0
  case "$connection" in
    SSH_CONNECTION=*) export SSH_CONNECTION="${connection#SSH_CONNECTION=}" ;;
    -SSH_CONNECTION) unset SSH_CONNECTION ;;
  esac
}

() {
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd tmux-sync-ssh
}

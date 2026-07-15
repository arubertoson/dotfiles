#!/bin/zsh

# Ignore insecure completion directories and let Znap cache the completion
# index. Completion reconciliation invalidates that cache when definitions move.
zstyle '*:compinit' arguments -i

# Keep automatic menus responsive without redrawing on every keystroke.
zstyle ':autocomplete:*' delay 0.1
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'
zstyle ':autocomplete:history-incremental-search-backward:*' list-lines 8
zstyle ':autocomplete:history-search-backward:*' list-lines 32

# Match case and separator variants, then prefer the common prefix when there
# are multiple candidates.
zstyle ':completion:*:*' matcher-list \
  'm:{[:lower:]-}={[:upper:]_}' '+r:|[.]=**'

# Tab enters the menu and cycles there; Shift-Tab moves backwards.
bindkey '^I' menu-select
bindkey -M menuselect '^I' menu-complete

if [[ -n ${terminfo[kcbt]:-} ]]; then
  bindkey "$terminfo[kcbt]" menu-select
  bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
fi

# Enter should execute the command rather than merely leave menu selection.
bindkey -M menuselect '^M' .accept-line

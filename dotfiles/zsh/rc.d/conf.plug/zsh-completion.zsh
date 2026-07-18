#!/bin/zsh

# Ignore insecure completion directories and let Znap cache the completion
# index. Completion reconciliation invalidates that cache when definitions move.
zstyle '*:compinit' arguments -i

# Match case and separator variants, then prefer the common prefix when there
# are multiple candidates.
zstyle ':completion:*:*' matcher-list \
  'm:{[:lower:]-}={[:upper:]_}' '+r:|[.]=**'

# Completion is requested explicitly with Tab; Shift-Tab moves backwards.
bindkey '^I' menu-select
bindkey -M menuselect '^I' menu-complete
bindkey -M menuselect '^N' menu-complete
bindkey -M menuselect '^P' reverse-menu-complete

if [[ -n ${terminfo[kcbt]:-} ]]; then
  bindkey "$terminfo[kcbt]" menu-select
  bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
fi

# Enter should execute the command rather than merely leave menu selection.
bindkey -M menuselect '^M' .accept-line

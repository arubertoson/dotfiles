#!/usr/bin/env zsh

fzf-tmux-workspace-bin() {
  command -v tmux-workspace 2>/dev/null || command -v tws 2>/dev/null || \
    print -r -- "$HOME/.local/bin/tmux-workspace"
}

fzf-pick-workspace-line() {
  local prompt="$1"
  local command="$2"
  local reload="${3:-}"
  local bind=()

  if [[ -n "$reload" ]]; then
    bind=(--bind "ctrl-r:reload($reload)+clear-query")
  fi

  eval "$command" | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-}" \
    fzf --ansi --no-hscroll --height=40% --layout=reverse --exit-0 \
      --delimiter=$'\t' --with-nth=1,2 --prompt="$prompt" "${bind[@]}"
}

fzf-workspace-path() {
  local selection="$1"
  local rest="${selection#*$'\t'}"

  print -r -- "${rest#*$'\t'}"
}

fzf-change-to-dev-project() {
  local picker selection kind dir command reload

  zle vi-insert

  picker="$(fzf-tmux-workspace-bin)"
  [[ -x "$picker" || -n "$(command -v tmux-workspace 2>/dev/null)" ]] || {
    zle reset-prompt
    return 0
  }

  command="${(q)picker} list-projects"
  reload="${(q)picker} list-projects --refresh"
  selection="$(fzf-pick-workspace-line 'project> ' "$command" "$reload")"

  if [[ -z "$selection" ]]; then
    zle reset-prompt
    return 0
  fi

  kind="${selection%%$'\t'*}"
  dir="$(fzf-workspace-path "$selection")"

  if [[ -z "${TMUX:-}" && "$kind" == git ]]; then
    BUFFER="builtin cd -- ${(q)dir}"
    zle silent-accept-line
    printf '\r\033[38;5;12m%s\033[0m' "$dir"
    zle accept-line
    return
  fi

  "$picker" open-path "$dir"
  zle reset-prompt
}

fzf-change-to-zoxide-directory() {
  local picker selection dir command

  zle vi-insert

  picker="$(fzf-tmux-workspace-bin)"
  [[ -x "$picker" || -n "$(command -v tmux-workspace 2>/dev/null)" ]] || {
    zle reset-prompt
    return 0
  }

  command="${(q)picker} list-zoxide"
  selection="$(fzf-pick-workspace-line 'zoxide> ' "$command")"

  if [[ -z "$selection" ]]; then
    zle reset-prompt
    return 0
  fi

  dir="$(fzf-workspace-path "$selection")"

  if [[ -z "${TMUX:-}" ]]; then
    BUFFER="builtin cd -- ${(q)dir}"
    zle silent-accept-line
    printf '\r\033[38;5;12m%s\033[0m' "$dir"
    zle accept-line
    return
  fi

  "$picker" open-path "$dir"
  zle reset-prompt
}

zle -N fzf-change-to-dev-project
zle -N fzf-change-to-zoxide-directory

bindkey -M viins '^[s' fzf-change-to-dev-project
bindkey -M vicmd '^[s' fzf-change-to-dev-project
bindkey -M viins '^[z' fzf-change-to-zoxide-directory
bindkey -M vicmd '^[z' fzf-change-to-zoxide-directory

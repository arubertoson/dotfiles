#!/usr/bin/env zsh

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf not found, not loading fzf config." >&2
  return 1
fi

FDFIND_COMMAND="$(command -v fd 2>/dev/null || command -v fdfind 2>/dev/null || true)"
FZF_DEFAULT_OPTS="--height=40% --layout=reverse"

fzf-echo-env() {
  local env=$(env | cut -f1 -d"=" | FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS} fzf)

  if [[ -z "$env" ]]; then
    zle reset-prompt
    return
  fi

  printenv "$env" | tr ":" "\n"
  zle reset-prompt
}

fzf-select-job() {
  local job=$(jobs | FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS} fzf | rg '[0-9]' -o)

  BUFFER="fg %${job}"
  zle accept-line
  zle reset-prompt
}

# Expose zle functions
zle -N fzf-echo-env
zle -N fzf-select-job

# fzf keybinds
bindkey -M vicmd '^@p' fzf-echo-env
bindkey -M vicmd '^@j' fzf-select-job

if [[ -n "$FDFIND_COMMAND" ]]; then
  export FZF_CTRL_T_COMMAND="$FDFIND_COMMAND . --hidden"
  export FZF_ALT_C_COMMAND="$FDFIND_COMMAND -HI --type directory"
fi

() {
  local file root="${${(%):-%N}:A:h}"

  for file in "$root"/fzf/*.zsh(N); do
    source "$file"
  done
}

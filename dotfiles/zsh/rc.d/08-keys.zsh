#!/bin/zsh

# Custom bindings load after all plugins so they intentionally override plugin
# defaults. Completion menu bindings live in conf.plug/zsh-completion.zsh.

# Enable the use of Ctrl-Q and Ctrl-S for keyboard shortcuts.
unsetopt FLOW_CONTROL

bindkey -M viins '^[' vi-cmd-mode
bindkey -M viins '^P' history-search-backward
bindkey -M viins '^N' history-search-forward
bindkey -M vicmd 'k' up-line-or-search
bindkey -M vicmd 'N' history-search-backward

cursor-set-vi-mode() {
  case ${KEYMAP:-viins} in
    vicmd) printf '\e[2 q' ;;
    *) printf '\e[6 q' ;;
  esac
}

keymap-ui-update() {
  cursor-set-vi-mode
  prompt_fruz_update_prompt
  zle .reset-prompt
}

# These standard widgets are registered once, after plugins, so cursor and
# prompt updates cannot replace one another.
zle-keymap-select() {
  keymap-ui-update
}

zle-line-init() {
  keymap-ui-update
}

zle -N zle-keymap-select
zle -N zle-line-init
cursor-set-vi-mode

# Ctrl-D to noop to avoid exiting the shell (so fucking tired of doing it)
noop() {}
zle -N noop

bindkey -M main '^d' noop
bindkey -M viins '^d' noop
bindkey -M emacs '^d' noop

# Alt-Q
# - On the main prompt: Push aside your current command line, so you can type a
#   new one. The old command line is re-inserted when you press Alt-G or
#   automatically on the next command line.
# - On the continuation prompt: Move all entered lines to the main prompt, so
#   you can edit the previous lines.
bindkey '^[q' push-line-or-edit

# Command line edit with editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Keep fzf history on Ctrl-R.
if (( ${+functions[fzf-history]} )); then
  zle -N fzf-history
  bindkey -M main '^r' fzf-history
  bindkey -M viins '^r' fzf-history
  bindkey -M emacs '^r' fzf-history
  bindkey -M vicmd '^Xr' fzf-history
fi

if (( ${+functions[fzf-echo-env]} )); then
  zle -N fzf-echo-env
  bindkey -M vicmd '^Xe' fzf-echo-env
fi

if (( ${+functions[fzf-change-to-dev-project]} )); then
  zle -N fzf-change-to-dev-project
  bindkey -M vicmd '^Xp' fzf-change-to-dev-project
fi

if (( ${+functions[fzf-change-to-zoxide-directory]} )); then
  zle -N fzf-change-to-zoxide-directory
  bindkey -M vicmd '^Xz' fzf-change-to-zoxide-directory
fi

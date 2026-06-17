#!/bin/zsh

##
# Key bindings
#
# zsh-autocomplete and zsh-edit add many useful keybindings. See each of their
# respective docs for the full list:
# https://github.com/marlonrichert/zsh-autocomplete/blob/main/README.md#key-bindings
# https://github.com/marlonrichert/zsh-edit/blob/main/README.md#key-bindings
#

# Enable the use of Ctrl-Q and Ctrl-S for keyboard shortcuts.
unsetopt FLOW_CONTROL

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

# fzf widgets
if (( ${+functions[fzf-history]} )); then
  zle -N fzf-history
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

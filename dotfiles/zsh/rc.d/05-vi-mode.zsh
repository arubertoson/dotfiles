#!/bin/zsh

# Select the native vi keymaps before zsh-autocomplete loads so the plugin
# installs its widgets against viins rather than the default emacs keymap.
bindkey -v

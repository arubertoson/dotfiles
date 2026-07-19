#!/bin/zsh

##
# Environment variables
#

# -U ensures each entry in these is unique (that is, discards duplicates).
export -U PATH path FPATH fpath MANPATH manpath
export -UT INFOPATH infopath # -T creates a "tied" pair; see below.

# ZK
export ZK_NOTEBOOK_DIR=~/notes

# $PATH and $path (and also $FPATH and $fpath, etc.) are "tied" to each other.
# Modifying one will also modify the other.
path=(
  ~/.local/bin
  $path
  $WIN32YANK
)

# Add your functions to your $fpath, so you can autoload them.
fpath=(
  $ZDOTDIR/functions
  ~/.local/share/zsh/site-functions
  $fpath
)

# Activate mise before completion initialization so its shims and generated
# completion functions are visible when Znap runs compinit.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi

source $ZDOTDIR/functions/llm-q

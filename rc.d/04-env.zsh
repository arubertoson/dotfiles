#!/bin/zsh

##
# Environment variables
#

# -U ensures each entry in these is unique (that is, discards duplicates).
export -U PATH path FPATH fpath MANPATH manpath
export -UT INFOPATH infopath  # -T creates a "tied" pair; see below.

# ZK
export ZK_NOTEBOOK_DIR=~/notes

# Prevent Ctrl+D from exiting the shell accidentally (requires 2 presses)
# Or set it to 0 if you want it to never exit via Ctrl+D
export IGNOREEOF=0

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
    $fpath
    ~/.local/share/zsh/site-functions
)

source $ZDOTDIR/functions/llm-q

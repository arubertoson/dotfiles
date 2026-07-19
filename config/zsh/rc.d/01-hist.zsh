#!/bin/zsh

##
# History settings
#
# Always set these first, so history is preserved, no matter what happens.
#

# Enable additional glob operators. (Globbing = pattern matching)
# https://zsh.sourceforge.io/Doc/Release/Expansion.html#Filename-Generation
setopt EXTENDED_GLOB

# Tell zsh where to store history, and just in case: If the parent directory 
# doesn't exist, create it.
HISTFILE=${XDG_CACHE_HOME:=~/.local/share}/zsh/history
[[ -d $HISTFILE:h ]] ||
    mkdir -p $HISTFILE:h

# Max number of entries to keep in history file.
SAVEHIST=$(( 100 * 1000 ))      # Use multiplication for readability.

# Max number of history entries to keep in memory.
HISTSIZE=$(( 1.2 * SAVEHIST ))  # Zsh recommended value

# Use modern file-locking mechanisms, for better safety & performance.
setopt HIST_FCNTL_LOCK

# Keep only the most recent copy of each duplicate entry in history.
setopt HIST_IGNORE_ALL_DUPS

# Auto-sync history between concurrent sessions.
setopt SHARE_HISTORY
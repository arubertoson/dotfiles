#!/bin/zsh
#
# This file, .zshrc, is sourced by zsh for each interactive shell session.
#
# Note: For historical reasons, there are other dotfiles, besides .zshenv and
# .zshrc, that zsh reads, but there is really no need to use those.

() {
  # `local` sets the variable's scope to this function and its descendendants.
  local gitdir=~/Git  # where to keep repos and plugins

  # Load all of the files in rc.d that start with <number>- and end in `.zsh`.
  # (n) sorts the results in numerical order.
  #  <->  is an open-ended range. It matches any non-negative integer.
  # <1->  matches any integer >= 1.
  #  <-9> matches any integer <= 9.
  # <1-9> matches any integer that's >= 1 and <= 9.
  # See https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators
  local file=
  for file in $ZDOTDIR/rc.d/<->-*.zsh(n); do
    . $file   # `.` is like `source`, but doesn't search your $path.
  done

# $@ expands to all the arguments that were passed to the current context (in
# this case, to `zsh` itself).
# "Double quotes" ensures that empty arguments '' are preserved.
# It's a good practice to pass "$@" by default. You'd be surprised at all the
# bugs you avoid this way.
} "$@"


# After init setup.
znap eval mise '~/.local/bin/mise activate zsh'
znap fpath _mise '~/.local/bin/mise completions zsh'
znap eval zoxide 'zoxide init zsh'

# Don't want to ahve the fzf plugin when we are handling the binary differntly...
# The setup though :(
znap eval fzf 'fzf --zsh'
source "$ZDOTDIR/rc.d/conf.plug/fzf.zsh"

# Clear the $TMUX variable if it's pointing to a non-existent socket
# This prevents the "nested with care" error if WSL is acting up
if [[ -n "$TMUX" ]] && ! tmux ls >/dev/null 2>&1; then
    unset TMUX
fi

# Only run if we are in an interactive shell and NOT already in tmux
if [[ -z "$TMUX" && -n "$PS1" ]]; then
    # 1. Try to attach to 'main'. If it fails, create 'main'.
    # 2. '&& exit' ensures that when you quit tmux, Alacritty closes immediately.
    (tmux attach-session -t main 2>/dev/null || tmux new-session -s main) && exit
fi

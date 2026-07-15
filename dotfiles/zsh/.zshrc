#!/bin/zsh
#
# This file, .zshrc, is sourced by zsh for each interactive shell session.
#
# Note: For historical reasons, there are other dotfiles, besides .zshenv and
# .zshrc, that zsh reads, but there is really no need to use those.

# Machine-local values are exported only for commands launched from interactive shells.
if [[ -f "$HOME/.env" ]]; then
  set -a
  source "$HOME/.env"
  set +a
fi

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
if command -v zoxide >/dev/null 2>&1; then
  znap eval zoxide 'zoxide init zsh'
fi

start-tmux() {
  # Ghostty+niri is now the local workspace layer. Keep tmux available, but
  # don't hide Ghostty's native protocols unless AUTO_TMUX=1 is explicit.
  [[ -z "${GHOSTTY_RESOURCES_DIR:-}" || -n "${AUTO_TMUX+x}" ]] || return
  [[ "${AUTO_TMUX:-1}" == 1 ]] || return
  [[ -z "${TMUX:-}" ]] || return
  [[ "${TERM:-}" != dumb ]] || return
  command -v tmux >/dev/null 2>&1 || return

  exec tmux new-session -A -s main
}

start-tmux

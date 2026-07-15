#!/bin/zsh

# Clone completion sources and interactive plugins in parallel. Completion
# directories must be on fpath before zsh-autocomplete initializes compinit.
local -a plugins=(
  marlonrichert/zsh-autocomplete
  marlonrichert/zcolors
  hlissner/zsh-autopair
  adrieankhisbe/zsh-quiet-accept-line
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

znap clone zsh-users/zsh-completions $plugins
fpath=(~[zsh-users/zsh-completions]/src $fpath)

# Autocomplete owns completion initialization and should load before plugins
# that wrap ZLE widgets. Local styles and keybindings intentionally apply after
# the plugin defaults.
znap source marlonrichert/zsh-autocomplete
source $ZDOTDIR/rc.d/conf.plug/zsh-autocomplete.zsh

znap source hlissner/zsh-autopair
znap source adrieankhisbe/zsh-quiet-accept-line
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

if command -v fzf >/dev/null 2>&1; then
  source $ZDOTDIR/rc.d/conf.plug/fzf.zsh
fi

znap eval zcolors zcolors

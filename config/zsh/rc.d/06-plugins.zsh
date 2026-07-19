#!/bin/zsh

# Clone completion sources and interactive plugins in parallel.
local -a plugins=(
  marlonrichert/zcolors
  hlissner/zsh-autopair
  adrieankhisbe/zsh-quiet-accept-line
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

znap clone zsh-users/zsh-completions $plugins
fpath=(~[zsh-users/zsh-completions]/src $fpath)
source $ZDOTDIR/rc.d/conf.plug/zsh-completion.zsh

znap source hlissner/zsh-autopair
znap source adrieankhisbe/zsh-quiet-accept-line
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

if command -v fzf >/dev/null 2>&1; then
  source $ZDOTDIR/rc.d/conf.plug/fzf.zsh
fi

znap eval zcolors zcolors

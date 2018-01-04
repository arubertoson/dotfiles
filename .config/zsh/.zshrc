export ZGEN_AUTOLOAD_COMPINIT=0
AUTOPAIR_INHIBIT_INIT=1

_load_repo tarjoilija/zgen $ZGEN_DIR zgen.zsh
if ! zgen saved; then
  echo "Creating zgen save"
  # _cache_clear

  zgen load hlissner/zsh-autopair autopair.zsh develop
  zgen load zsh-users/zsh-history-substring-search
  zgen load zdharma/history-search-multi-word
  zgen load zsh-users/zsh-completions src
  zgen load junegunn/fzf shell
  zgen load zdharma/fast-syntax-highlighting

  zgen save
fi

# usr cfg
source "${ZDOTDIR}/config.zsh"
source "${ZDOTDIR}/completions.zsh"
source "${ZDOTDIR}/keymaps.zsh"
source "${ZDOTDIR}/prompt.zsh"

#
autopair-init

# 
autoload -Uz compinit && compinit -d $ZSH_CACHE/zcompdump

# usr alias
source "${ZDOTDIR}/aliases.zsh"

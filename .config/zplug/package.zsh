#
# Prezto
#
zplug "modules/environment", from:prezto
zplug "modules/utility", from:prezto

zplug "modules/history", from:prezto
zplug "modules/directory", from:prezto
zplug "modules/archive", from:prezto

#zplug "modules/node", from:prezto
zplug "modules/pacman", from:prezto

zplug "modules/completion", from:prezto
#zplug "modules/fasd", from:prezto
#zplug "modules/syntax-highlighting", from:prezto, defer:2
#zplug "modules/history-substring-search", from:prezto, defer:3
#zplug "modules/prompt", from:prezto, defer:3

# Prezto settings
zstyle ':prezto:module:pacman' frontend 'pacaur'

#
#
#
zplug "hlissner/zsh-autopair", use:"autopair.zsh", defer:2
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
#zplug "zsh-users/zsh-history-substring-search", defer:3
#zplug "momo-lab/zsh-abbrev-alias"
zplug "mafredri/zsh-async", on:sindresorhus/pure
zplug "sindresorhus/pure", use:pure.zsh, as:theme
zplug "b4b4r07/enhancd", use:init.sh

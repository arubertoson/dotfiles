#
# Prezto
#
# zplug "modules/node", from:prezto
# zplug "modules/fasd", from:prezto
# zplug "modules/rsync", from:prezto
zplug "modules/environment", from:prezto
zplug "modules/archive", from:prezto
zplug "modules/directory", from:prezto
zplug "modules/history", from:prezto
zplug "modules/utility", from:prezto
#zplug "modules/pacman", from:prezto
zstyle ':prezto:module:pacman' frontend 'pacaur'
 
#
# Prompt
#
zplug "mafredri/zsh-async", on:sindresorhus/pure
zplug "sindresorhus/pure", use:pure.zsh, as:theme
 
# 
# Completions
#
zplug "akoenig/gulp.plugin.zsh"
zplug "lukechilds/zsh-better-npm-completion"
zplug "srijanshetty/zsh-pip-completion"

#
# Shell 
#
# zplug "momo-lab/zsh-abbrev-alias"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "hlissner/zsh-autopair", \
  use:"autopair.zsh", \
  defer:2

#
# Others
#
zplug "mollifier/anyframe"

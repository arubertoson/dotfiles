#
# Environment for interactive sessions
#

setopt sunkeyboardhack

fpath=(  
  $ZDOTDIR/functions
  $ZDOTDIR/compdef
  $fpath
)


# source Zsh configs
for src in $ZDOTDIR/zshrc.d/*; do
  source $src
done
unset src

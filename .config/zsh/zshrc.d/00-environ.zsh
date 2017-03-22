# 
# Environment variables for session and apps
# 


export FILTER_ENGINE
declare -a arr=("fzy" "fzf" "peco" "percol") 
for filter in "${arr[@]}"
do
  if (( $+commands[$filter] ))
  then
    FILTER_ENGINE=$filter
    break
  fi
done


if (( $+commands[tig] ))
then
export TIGRC_USER="$XDG_CONFIG_HOME/tig/config"
fi

if (( $+commands[npm] ))
then
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
fi

eval "$(dircolors $HOME/.dir_colors)"

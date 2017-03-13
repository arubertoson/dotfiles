# 
# Environment variables for session and apps
# 

function filter-engine() {
  echo -n "Setting main filter engine..."
  export FILTER_ENGINE
  declare -a arr=("fzy" "fzf" "peco" "percol") 
  for filter in "${arr[@]}"
  do
    if (( $+commands[$filter] ))
    then
      echo " $filter"
      FILTER_ENGINE=$filter
      break
    fi
  done
}

function tig() {
  if (( $+commands[tig] ))
  then
    export TIGRC_USER="$XDG_CONFIG_HOME/tig/config"
  fi
}

function npm() {
  if (( $+commands[npm] ))
  then
    export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
    export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
    export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
  fi
}

filter-engine
tig
npm

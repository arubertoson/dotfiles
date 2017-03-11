# 
# Environment variables for session and apps
# 

#enhancd
export ENHANCD_DIR="$XDG_DATA_HOME/enhancd"

#tig
if (( $+commands[tig] )); then
  export TIGRC_USER="$XDG_CONFIG_HOME/tig/config"
fi

#npm
if (( $+commands[npm] )); then
  export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
  export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
  export NPM_CONFIG_PREFIX+"$XDG_DATA_HOME/npm"
fi

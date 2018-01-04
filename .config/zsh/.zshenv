#!/usr/bin/env zsh
# 
# Defines runtime environment
#

# source usr environment

export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_BIN_HOME="${HOME}/.local/bin"
export XDG_DATA_HOME="${HOME}/.local/share"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZGEN_DIR="$XDG_CACHE_HOME/zgen"
export ZSH_CACHE="$XDG_CACHE_HOME/zsh"

#
# Environment variables
#
export SHELL=$(command -v zsh)
export LANG=${LANG:-en_US.UTF-8}
export PAGER=less
export LESS='-R -i -w -M -z-4'
export LESSHISTFILE="$XDG_DATA_HOME/lesshst"


#
# Functions
#
function _is_callable {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null || return 1
  done
}

function _load_repo {
  _get_repo "$1" "$2" && source "$2/$3" || >&2 echo "Failed to load $1"
}


function _get_repo {
  local target=$1
  local dest=$2
  if [[ ! -d $dest ]]; then
    url=https://github.com/$target
    git clone --recursive "$url" "$dest" || return 1
  fi
}


function _cache_clear {
  command rm -rfv $XDG_CACHE_HOME/${SHELL##*/}/*;
}



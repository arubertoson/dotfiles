#!/usr/bin/env sh
#
# Defines runtime environment
#
export LOCAL_BIN="${HOME}/.local/bin"
export LOCAL_ETC="${HOME}/.local/etc"
export LOCAL_LIB="${HOME}/.local/lib"
export LOCAL_VAR="${HOME}/.local/var"
export LOCAL_SHARE="${HOME}/.local/share"

export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_RUNTIME_DIR="${HOME}/.local/run"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"

# TODO: Implement save state (jaagr/dots)
#export BSPWM_STATE="${XDG_CACHE_HOME}/bspwm/state.json"
#export BSPWM_FIFO="${XDG_CACHE_HOME}/bspwm/wm_state"

export LANG="en_US.UTF-8"
# export BROWSER=

export vim="nvim"
export EDITOR="nvim"
export VISUAL="nvim"

export NPM_BIN="${LOCAL_SHARE}/npm/bin"

export PATH="${PATH}:${LOCAL_BIN}:${NPM_BIN}"

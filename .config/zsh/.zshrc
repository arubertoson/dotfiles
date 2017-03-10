#
# Environment for interactive sessions
#

setopt sunkeyboardhack

fpath=(  
  $ZDOTDIR/compdef
  $fpath
)

#
# Init Zplug
#
#TODO: lift out to plugins.zsh

export ZPLUG_HOME="${LOCAL_SHARE}/zplug"
export ZPLUG_THREADS=8
export ZPLUG_CONFIG_DIR="${XDG_CONFIG_HOME}/zplug"
export ZPLUG_LOADFILE="${ZPLUG_CONFIG_DIR}/package.zsh"
export ZPLUG_CACHE_DIR="${XDG_CACHE_HOME}/zplug"

[[ -d $ZPLUG_HOME ]] || curl -sL zplug.sh/installer | zsh

# Change default path of zplugs
if [[ -d $ZPLUG_HOME ]]; then
  source $ZPLUG_HOME/init.zsh
  zplug check || zplug install
  zplug load # --verbose
fi

#
# Functions
#

# Lift out to zle-funcs.zsh 
unset flowcontrol

FZY=(fzy -p='|')

function zle::cmd() {
  LBUFFER="${(q)@}"
  zle reset-prompt
  zle .accept-line
}

function zle::insert-text() {
  echo 
  LBUFFER+="${(q)@}"
  zle reset-prompt
}

function zle::insert-path() {
	zle::insert-text $(find -type d | ${FZY[@]})
}
zle -N zle::insert-path

function zle::cd() {
  zle::cmd "$(find -type d | fzy)"
}
zle -N zle::cd

function zle::cd-project() {
  zle::cmd "$(find ~/projects -maxdepth 2 -type d | fzy)"
}
zle -N zle::cd-project

function zle::locate() {
  zle::insert-text "$(locate * | fzy)"
}
zle -N zle::locate

function zle::locate-find() {
  zle::insert-text "$(find -type f | fzy)"
}
zle -N zle::locate-find

function zle::locate-dir() {
  zle::insert-text "$(find -type d | fzy)"
}
zle -N zle::locate-dir

function zle::locate-history() {
  zle::insert-text "$(history -n | fzy)"
}
zle -N zle::locate-history


# TODO: Lift out to module keymap.zsh
bindkey -v
export KEYTIMEOUT=20

bindkey -M vicmd "gd" zle::cd
bindkey -M vicmd "gp" zle::cd-project

bindkey -M viins "^H" zle::locate-history
bindkey -M vicmd "^H" zle::locate-history

bindkey -M viins "^D" zle::locate-dir
bindkey -M vicmd "^D" zle::locate-dir

bindkey -M viins "^F" zle::locate
bindkey -M vicmd "^F" zle::locate

bindkey -M viins "kj" vi-cmd-mode


# Add time and vi-mode indicator to prompt
# TODO: lift out to prompt.zsh
VIM_PROMPT="❯"
PROMPT='%F{white}%* %(?.%F{magenta}.%F{red})${VIM_PROMPT}%f '

prompt_pure_update_vim_prompt() {
    zle || {
        print "error: pure_update_vim_prompt must be called when zle is active"
        return 1
    }
    VIM_PROMPT=${${KEYMAP/vicmd/❮}/(main|viins)/❯}
    zle .reset-prompt
}

function zle-line-init zle-keymap-select { 
    prompt_pure_update_vim_prompt
}
zle -N zle-line-init
zle -N zle-keymap-select 

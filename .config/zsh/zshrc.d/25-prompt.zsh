#
# Prompt Pure
#

# Change color on cursor depending on vi mode
ZSH_VICMD_CURSOR="#51afef"
ZSH_VIINS_CURSOR="#DFDFDF"

zsh-keymap-select-vicursor() {
  if [[ $KEYMAP == vicmd ]]; then
    echo -ne "\e[1 q"
    echo -ne "\033]12;$ZSH_VICMD_CURSOR\033\\"
  else
    # If we want a beam in insert mode uncomment
    # echo -ne "\e[5 q"
    echo -ne "\033]12;#DFDFDF\033\\"
  fi
}

zsh-update-vim-prompt() {
    zle || {
        print "error: pure_update_vim_prompt must be called when zle is active"
        return 1
    }

    #PURE_PROMPT_SYMBOL=${${KEYMAP/vicmd/«}/(main|viins)/»}
    PURE_PROMPT_SYMBOL=${${KEYMAP/vicmd/❮}/(main|viins)/❯}
    zle .reset-prompt
}


# Hook to zle functions
function zle-line-init zle-keymap-select { 
    zsh-keymap-select-vicursor
    #zsh-update-vim-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select 

#
# Modify Prompt
#

function bg_jobs() {
  echo "%{$fg[yellow]%}%(1j.[+%j] .)"
}

function time_() {
  echo "%F{white}%* "
}

# ❯ »
PURE_PROMPT_SYMBOL='❯'
PURE_GIT_DOWN_ARROW='↑'
PURE_GIT_UP_ARROW='↓'
PROMPT='$(bg_jobs)$(time_)%(?.%F{magenta}.%F{red})${PURE_PROMPT_SYMBOL}%f '
#PROMPT='$(bg_jobs)$(time_)'$PROMPT

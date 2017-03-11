#
# Prompt Pure
#

# Add timestamp in front of prompt
PROMPT='%F{white}%* '$PROMPT

# Custom cursor colors
ZSH_VICMD_CURSOR="#51afef"
ZSH_VIINS_CURSOR="#DFDFDF"

# Change color cursor with vi-mode
zsh-keymap-select-vicursor() {
  if [[ $KEYMAP == vicmd ]]; then
    echo -ne "\e[1 q"
    echo -ne "\033]12;$ZSH_VICMD_CURSOR\033\\"
  else
    # echo -ne "\e[5 q"
    echo -ne "\033]12;#DFDFDF\033\\"
  fi
}

# Hook to zle functions
function zle-line-init zle-keymap-select { 
    zsh-keymap-select-vicursor
}
zle -N zle-line-init
zle -N zle-keymap-select 

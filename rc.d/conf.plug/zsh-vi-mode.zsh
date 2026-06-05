bindkey -v
bindkey '^[' vi-cmd-mode
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

bindkey -M vicmd 'k' up-line-or-search
bindkey -M vicmd 'N' history-search-backward

echo -en '\x1b[6 q'

cursor-set-vi-mode() {
  case $KEYMAP in
    vicmd) echo -en '\x1b[2 q' ;;
    main|viins) echo -en '\x1b[6 q' ;;
  esac

  if (( $+functions[prompt_fruz_update_prompt] )); then
    prompt_fruz_update_prompt
    zle .reset-prompt
  fi
}

zle -N zle-keymap-select cursor-set-vi-mode
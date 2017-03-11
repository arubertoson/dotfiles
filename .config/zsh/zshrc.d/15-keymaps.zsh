#
# Keymaps
#

# Use vim keymaps with 0.2 timout
bindkey -d
bindkey -v
export KEYTIMEOUT=20

bindkey -r "^["
bindkey -rpM viins "^["
bindkey -rpM vicmd "^["


#bindkey -M vicmd "gd" zle::cd
#bindkey -M vicmd "gp" zle::cd-project


#bindkey -M viins "^H" zle::locate-history
#bindkey -M vicmd "^H" zle::locate-history

#bindkey -cM viins "^D" zle::locate-dir
#bindkey -cM vicmd "^D" zle::locate-dir

#bindkey -M viins "^F" zle::locate
#bindkey -M vicmd "^F" zle::locate

bindkey -M viins "kj" vi-cmd-mode

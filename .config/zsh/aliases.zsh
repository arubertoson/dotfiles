autoload -U zmv

zman() { PAGER="less -g -s '+/^       "$1"'" man zshall; }

# dotfiles
alias dots='git --git-dir=$HOME/.dots --work-tree=$HOME'
alias dots-ls='dots ls-files'
alias dots-ls-untracked='dots status -u .'

# aliases common to all shells
alias q=exit
alias clr=clear
alias sudo='sudo '

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias ln="${aliases[ln]:-ln} -v"  # verbose ln
alias l='ls -1'
alias ll='ls -l'
alias la='LC_COLLATE=C ls -la'

# notify me before clobbering files
alias rm='rm -i -v'
alias cp='cp -i -v'
alias mv='mv -i -v'

alias gurl='curl --compressed'
alias mkdir='mkdir -p'
alias rsyncd='rsync -va --delete'   # Hard sync two directories
alias wget='wget -c'                # Resume dl if possible

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ag="noglob ag -p $XDG_CONFIG_HOME/ag/agignore"
alias rg='noglob rg'

# For example, to list all directories that contain a certain file: find . -name
# .gitattributes | map dirname
alias map="xargs -n1"


# Conviniece
alias nvim=nvim -u $HOME/.vim/vimrc


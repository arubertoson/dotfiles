#####################################################################
# init
#####################################################################

# zmodload zsh/zprof

if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
fi

PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

#####################################################################
# zplug
#####################################################################

# Check if zplug is installed
[[ -f ~/.zplug/init.zsh ]] || return

unset ZPLUG_SHALLOW

# Essential
source ~/.zplug/init.zsh

# Completions
zplug "zsh-users/zsh-completions"
zplug "bobthecow/git-flow-completion"
zplug "srijanshetty/zsh-pip-completion"

zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-autosuggestions"

zplug "mafredri/zsh-async"


# Experimental
zplug "arzzen/calc.plugin.zsh"
zplug "rimraf/k"
zplug "sindresorhus/pure"
zplug "b4b4r07/enhancd"
zplug "hlissner/zsh-autopair"
zplug "soimort/translate-shell"


# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    else
        echo
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load


#####################################################################
# environment
#####################################################################

export EDITOR=nvim
export LANG=en_US.UTF-8

# Better umask
umask 022

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# improved less option
export LESS='--tabs=4 --no-init --LONG-PROMPT --ignore-case --quit-if-one-screen --RAW-CONTROL-CHARS'

#####################################################################
# options
######################################################################

setopt auto_resume
# Ignore <C-d> logout
setopt ignore_eof
# Disable beeps
setopt no_beep
# {a-c} -> a b c
setopt brace_ccl
# Enable spellcheck
setopt correct
# Enable "=command" feature
setopt equals
# Disable flow control
setopt no_flow_control
# Ignore dups
setopt hist_ignore_dups
# Reduce spaces
setopt hist_reduce_blanks
# Ignore add history if space
setopt hist_ignore_space
# Save time stamp
setopt extended_history
# Expand history
setopt hist_expand
# Better jobs
setopt long_list_jobs
# Enable completion in "--option=arg"
setopt magic_equal_subst
# Add "/" if completes directory
setopt mark_dirs
# Disable menu complete for vimshell
setopt no_menu_complete
setopt list_rows_first
# Expand globs when completion
setopt glob_complete
# Enable multi io redirection
setopt multios
# Can search subdirectory in $PATH
setopt path_dirs
# For multi byte
setopt print_eightbit
# Print exit value if return code is non-zero
setopt print_exit_value
setopt pushd_ignore_dups
setopt pushd_silent
# Short statements in for, repeat, select, if, function
setopt short_loops
# Ignore history (fc -l) command in history
setopt hist_no_store
setopt transient_rprompt
unsetopt promptcr
setopt hash_cmds
setopt numeric_glob_sort
# Enable comment string
setopt interactive_comments
# Improve rm *
setopt rm_star_wait
# Enable extended glob
setopt extended_glob

# List completion
setopt auto_list
setopt auto_param_slash
setopt auto_param_keys
# List like "ls -F"
setopt list_types
# Compact completion
setopt list_packed
setopt auto_cd
setopt auto_pushd
setopt pushd_minus
setopt pushd_ignore_dups
# Check original command in alias completion
setopt complete_aliases
unsetopt hist_verify


#####################################################################
# alias
######################################################################

# Better mv, cp, mkdir
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'


alias vim='nvim'


#####################################################################
# keybinds
######################################################################

# emacs keybinds
bindkey -v

bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Like bash
bindkey "^u" backward-kill-line


#####################################################################
# functions
######################################################################

# Set environment variables easily
setenv () { export $1="$@[2,-1]" }

r() {
    source ~/.zshrc
    if [ -d ~/.zsh/comp ]; then
        # Reload complete functions
        local f
        f=(~/.zsh/comp/*(.))
        unfunction $f:t 2> /dev/null
        autoload -U $f:t
    fi
}


#####################################################################
# others
######################################################################

# Improve terminal title
case "${TERM}" in
    kterm*|xterm*|vt100|st*|rxvt*)
        precmd() {
            echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
            vcs_info
        }
        ;;
esac

# Share zsh histories
HISTFILE=$HOME/.zsh-history
HISTSIZE=10000
SAVEHIST=50000
setopt inc_append_history
setopt share_history

# Enable math functions
zmodload zsh/mathfunc


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

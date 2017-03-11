#
# Zle Functions
# 

# Avoid hanging in term
unset flowcontrol


# Insert text and launch at cursor point
function zle::cmd() {
  LBUFFER="${(q)@}"
  zle reset-prompt
  zle .accept-line
}

# Insert text at cursor point
function zle::insert-text() {
  LBUFFER+="${(q)@}"
  zle reset-prompt
}

# Using fzy find get a path from find
function zle::insert-path() {
  zle::insert-text $(find -type d | fzy)
}
zle -N zle::insert-path

# cd to location
function zle::cd() {
  zle::cmd "$(find -type d | fzy)"
}
zle -N zle::cd

# cd to project location
function zle::cd-project() {
  zle::cmd "$(find ~/projects -maxdepth 2 -type d | fzy)"
}
zle -N zle::cd-project

# insert file using locate
function zle::locate() {
  zle::insert-text "$(locate * | fzy)"
}
zle -N zle::locate

function zle::go-git() {
  cd "$(locate ~/**/*.git | \
	  xargs -n1 dirname | \
	  # xargs -n1 basename | \
	  sort | uniq | fzy)"
}
zle -N zle::go-git

# insert file using find
function zle::locate-find() {
  zle::insert-text "$(find -type f | fzy)"
}
zle -N zle::locate-find

# insert dir using find
function zle::locate-dir() {
  zle::insert-text "$(find -type d | fzy)"
}
zle -N zle::locate-dir

# launch history command
function zle::locate-history() {
  zle::cmd "$(fc -ln | fzy)"
}
zle -N zle::locate-history

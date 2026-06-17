list-sessions() {
  tmux list-sessions -F $'#{session_windows} windows\t#{session_attached} attached\t#S' 2>/dev/null || true
}

pick-session() {
  local selection session cmd

  require-fzf
  cmd="tmux list-sessions -F '#{session_windows} windows	#{session_attached} attached	#S'"

  selection="$(list-sessions | FZF_DEFAULT_OPTS="$FZF_OPTS" \
    fzf --ansi --no-hscroll --height="$FZF_HEIGHT" --layout=reverse --border \
      --delimiter=$'\t' --with-nth=1,2,3 --prompt='session> ' \
      --header='enter: switch · ctrl-d: kill · ctrl-r: refresh' \
      --bind "ctrl-d:execute-silent(tmux kill-session -t {3})+reload($cmd)+clear-query" \
      --bind "ctrl-r:reload($cmd)+clear-query")"

  [[ -n "$selection" ]] || exit 0
  session="${selection##*$'\t'}"
  switch-session "$session"
}

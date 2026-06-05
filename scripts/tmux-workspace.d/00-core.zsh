usage() {
  print -r -- 'usage: tmux-workspace [project|zoxide|sessions|list-projects|list-zoxide|open-path PATH]'
}

fd-cmd() {
  command -v fdfind 2>/dev/null || command -v fd 2>/dev/null || true
}

require-fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -r -- 'tmux-workspace: fzf not found'
    exit 1
  fi
}

pretty-path() {
  local dir="$1"

  if [[ "$dir" == "$DEV_ROOT"/* ]]; then
    print -r -- "~dev/${dir#$DEV_ROOT/}"
    return
  fi

  if [[ "$dir" == "$HOME"/* ]]; then
    print -r -- "~/${dir#$HOME/}"
    return
  fi

  print -r -- "$dir"
}

abs-path() {
  local dir="$1"
  local base="${2:-$DEV_ROOT}"

  case "$dir" in
    '~dev') print -r -- "$DEV_ROOT" ;;
    '~dev/'*) print -r -- "$DEV_ROOT/${dir#\~dev/}" ;;
    '~') print -r -- "$HOME" ;;
    '~/'*) print -r -- "$HOME/${dir#\~/}" ;;
    /*) print -r -- "$dir" ;;
    *) print -r -- "$base/$dir" ;;
  esac
}

pattern-path() {
  local pattern="$1"

  case "$pattern" in
    '~dev') print -r -- "$DEV_ROOT" ;;
    '~dev/'*) print -r -- "$DEV_ROOT/${pattern#\~dev/}" ;;
    '~') print -r -- "$HOME" ;;
    '~/'*) print -r -- "$HOME/${pattern#\~/}" ;;
    *) print -r -- "$pattern" ;;
  esac
}

session-name() {
  local dir="$1"
  local name="${dir:t}"

  name="${name//./_}"
  name="${name//:/_}"
  print -r -- "$name"
}

windows-for() {
  local dir="$1"
  local rule pattern windows

  for rule in "${TMUX_WORKSPACE_LAYOUTS[@]}"; do
    pattern="${rule%%:*}"
    windows="${rule#*:}"
    pattern="$(pattern-path "$pattern")"

    if [[ "$dir" == ${~pattern} ]]; then
      print -r -- "$windows"
      return
    fi
  done

  print -r -- 'code misc'
}

ensure-session() {
  local dir="$1"
  local session window windows
  typeset -a names

  session="$(session-name "$dir")"

  if tmux has-session -t="$session" 2>/dev/null; then
    print -r -- "$session"
    return
  fi

  windows="$(windows-for "$dir")"
  names=(${=windows})
  [[ ${#names[@]} -gt 0 ]] || names=(code misc)

  tmux new-session -ds "$session" -n "${names[1]}" -c "$dir"
  for window in "${names[@]:1}"; do
    tmux new-window -t "$session" -n "$window" -c "$dir"
  done

  print -r -- "$session"
}

switch-session() {
  local session="$1"

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
    return
  fi

  tmux attach-session -t "$session"
}

pick-lines() {
  local prompt="$1"
  local reload="${2:-}"
  local bind=()

  require-fzf

  if [[ -n "$reload" ]]; then
    bind=(--bind "ctrl-r:reload($reload)+clear-query")
  fi

  FZF_DEFAULT_OPTS="$FZF_OPTS" \
    fzf --ansi --no-hscroll --height="$FZF_HEIGHT" --layout=reverse --border \
      --delimiter=$'\t' --with-nth=1,2 --prompt="$prompt" "${bind[@]}"
}

selected-path() {
  local selection="$1"
  local rest

  rest="${selection#*$'\t'}"
  print -r -- "${rest#*$'\t'}"
}

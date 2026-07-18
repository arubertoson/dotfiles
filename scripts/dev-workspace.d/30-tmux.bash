tmux-legacy-session-name() {
  local dir="$1"
  local parent
  local name

  parent="$(basename "$(dirname "$dir")")"
  name="$parent-$(basename "$dir")"
  name="${name//./_}"
  name="${name//:/_}"
  name="${name// /_}"
  printf '%s\n' "$name"
}

tmux-layout() {
  local dir="$1"

  if [[ "$dir" == "$DEV_ROOT"/* ]]; then
    printf '%s\n' 'dev term agent serv'
    return
  fi

  printf '%s\n' 'dev term'
}

tmux-restore-layout() {
  local dir="$1"
  local session="$2"
  local layout
  local name
  local existing
  local names=()

  layout="$(tmux-layout "$dir")"
  existing="$(tmux list-windows -t "=$session" -F '#W' 2>/dev/null || true)"

  if ! grep -Fqx dev <<<"$existing" && grep -Fqx code <<<"$existing"; then
    tmux rename-window -t "=$session:code" dev
    existing="$(sed 's/^code$/dev/' <<<"$existing")"
  fi

  read -r -a names <<<"$layout"
  for name in "${names[@]}"; do
    if grep -Fqx -- "$name" <<<"$existing"; then
      continue
    fi

    tmux new-window -d -t "=$session" -n "$name" -c "$dir"
  done
}

tmux-session-matches-path() {
  local session="$1"
  local dir="$2"

  tmux list-panes -t "=$session" -F '#{pane_start_path}' 2>/dev/null | grep -Fqx -- "$dir"
}

tmux-ensure-session() {
  local dir="$1"
  local session
  local legacy
  local layout
  local first
  local name
  local names=()

  session="$(session-name "$dir")"
  if tmux has-session -t "=$session" 2>/dev/null; then
    tmux-restore-layout "$dir" "$session"
    printf '%s\n' "$session"
    return
  fi

  legacy="$(tmux-legacy-session-name "$dir")"
  if [[ "$legacy" != "$session" ]] && \
    tmux has-session -t "=$legacy" 2>/dev/null && \
    tmux-session-matches-path "$legacy" "$dir"; then
    tmux-restore-layout "$dir" "$legacy"
    printf '%s\n' "$legacy"
    return
  fi

  layout="$(tmux-layout "$dir")"
  read -r -a names <<<"$layout"
  first="${names[0]}"
  tmux new-session -ds "$session" -n "$first" -c "$dir"

  for name in "${names[@]:1}"; do
    tmux new-window -d -t "=$session" -n "$name" -c "$dir"
  done

  printf '%s\n' "$session"
}

tmux-switch-session() {
  local session="$1"

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "=$session"
    return
  fi

  tmux attach-session -t "=$session"
}

tmux-open-path() {
  require tmux

  local dir
  local session

  dir="$(canonical-path "$1")"
  [[ -d "$dir" ]] || { echo "dev-workspace: not a directory: $dir" >&2; exit 1; }

  session="$(tmux-ensure-session "$dir")"
  tmux-switch-session "$session"
}

tmux-pick-project() {
  local dir

  dir="$(pick-project-path)"
  [[ -n "$dir" ]] || return 0
  tmux-open-path "$dir"
}

tmux-pick-zoxide() {
  local dir

  dir="$(pick-zoxide-path)"
  [[ -n "$dir" ]] || return 0
  tmux-open-path "$dir"
}

tmux-list-sessions() {
  tmux list-sessions -F $'#{session_windows} windows\t#{session_attached} attached\t#S' \
    2>/dev/null || true
}

tmux-pick-session-rofi() {
  local result
  local code
  local session

  while true; do
    result="$(tmux-list-sessions | pick-lines 'session >' custom-delete)" || return 0
    code="${result%%$'\t'*}"
    session="${result##*$'\t'}"
    [[ -n "$session" ]] || return 0

    case "$code" in
      0) tmux-switch-session "$session"; return ;;
      10) tmux kill-session -t "=$session"; continue ;;
      *) return 0 ;;
    esac
  done
}

tmux-pick-session-fzf() {
  local selection
  local session
  local command

  command="tmux list-sessions -F '#{session_windows} windows	#{session_attached} attached	#S'"
  selection="$(tmux-list-sessions | FZF_DEFAULT_OPTS="$FZF_OPTS" \
    fzf --ansi --no-hscroll --height="$FZF_HEIGHT" --layout=reverse --border \
      --delimiter=$'\t' --with-nth=1,2,3 --prompt='session >' \
      --header='enter: switch · ctrl-d: kill · ctrl-r: refresh' \
      --bind "ctrl-d:execute-silent(tmux kill-session -t {3})+reload($command)+clear-query" \
      --bind "ctrl-r:reload($command)+clear-query")" || return 0

  [[ -n "$selection" ]] || return 0
  session="${selection##*$'\t'}"
  tmux-switch-session "$session"
}

tmux-pick-session() {
  require tmux

  case "$(picker)" in
    rofi) tmux-pick-session-rofi ;;
    fzf) require fzf; tmux-pick-session-fzf ;;
  esac
}

tmux-new() {
  require tmux

  local meta
  local slot

  meta="$(slot-meta "${1:-term}")"
  slot="${meta%%$'\t'*}"

  case "$slot" in
    dev)
      tmux new-window -c '#{pane_current_path}' -n dev \
        '${EDITOR:-nvim} .; exec ${SHELL:-sh}'
      ;;
    term)
      tmux new-window -c '#{pane_current_path}' -n term
      ;;
    agent)
      tmux new-window -c '#{pane_current_path}' -n agent \
        'if command -v pi >/dev/null 2>&1; then pi; fi; exec ${SHELL:-sh}'
      ;;
    serv)
      tmux new-window -c '#{pane_current_path}' -n serv \
        'if command -v just >/dev/null 2>&1; then just; fi; exec ${SHELL:-sh}'
      ;;
  esac
}

tmux-slot() {
  require tmux

  local meta
  local slot
  local index

  meta="$(slot-meta "${1:-dev}")"
  slot="${meta%%$'\t'*}"
  index="${meta#*$'\t'}"

  tmux select-window -t ":$slot" 2>/dev/null || tmux select-window -t "$index"
}

tmux-windows() {
  require tmux

  local selection
  local index

  selection="$(tmux list-windows -F '#I\t#W\t#{pane_current_command}' | \
    pick-lines 'window >')" || return 0
  [[ -n "$selection" ]] || return 0

  index="${selection%%$'\t'*}"
  tmux select-window -t "$index"
}

tmux-dispatch() {
  case "${1:-project}" in
    project|projects) tmux-pick-project ;;
    zoxide|z) tmux-pick-zoxide ;;
    sessions|session|active) tmux-pick-session ;;
    windows|window|win) tmux-windows ;;
    open-path|restore-path)
      shift
      [[ $# -gt 0 ]] || { usage >&2; exit 1; }
      tmux-open-path "$1"
      ;;
    toggle|previous|back) require tmux; tmux switch-client -l ;;
    new) shift; tmux-new "${1:-term}" ;;
    slot) shift; tmux-slot "${1:-dev}" ;;
    list-projects) shift; list-projects "${1:-}" ;;
    list-zoxide) list-zoxide ;;
    --help|-h|help) usage ;;
    *) usage >&2; exit 1 ;;
  esac
}

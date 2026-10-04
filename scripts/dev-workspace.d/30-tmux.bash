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

tmux-agent-center-layout() {
  [[ $# == 1 && "$1" =~ ^%[0-9]+$ ]] || return 1

  local center="$1"
  local existing
  local panes
  local window

  existing="$(tmux display-message -p -t "$center" '#{@dev_workspace_agent_center}' 2>/dev/null || true)"
  if [[ "$existing" != 1 ]]; then
    panes="$(tmux list-panes -t "$center" -F '#{pane_id}')"
    [[ "$panes" == "$center" ]] || return 0
    tmux set-option -p -t "$center" @dev_workspace_agent_center 1
  fi

  window="$(tmux display-message -p -t "$center" '#{window_id}')"
  tmux-agent-resize-layout "$window"
  tmux select-pane -t "$center"
}

tmux-agent-focus() {
  [[ $# == 1 && "$1" =~ ^%[0-9]+$ ]] || return 0

  local gutter
  local center

  gutter="$(tmux display-message -p -t "$1" '#{@dev_workspace_agent_gutter}' 2>/dev/null || true)"
  [[ "$gutter" == 1 ]] || return 0
  center="$(tmux list-panes -t "$1" -F '#{pane_id} #{@dev_workspace_agent_center}' |
    awk '$2 == 1 { print $1; exit }')"
  [[ "$center" =~ ^%[0-9]+$ ]] || return 0
  tmux select-pane -t "$center"
}

tmux-agent-resize-layout() {
  [[ $# == 1 && "$1" =~ ^@[0-9]+$ ]] || return 0

  local window="$1"
  local width
  local min_width=100
  local center
  local gutter
  local zoomed
  local -a gutters=()

  zoomed="$(tmux display-message -p -t "$window" '#{window_zoomed_flag}')"
  [[ "$zoomed" == 1 ]] && return 0
  width="$(tmux display-message -p -t "$window" '#{window_width}')"
  center="$(tmux list-panes -t "$window" -F '#{pane_id} #{@dev_workspace_agent_center}' |
    awk '$2 == 1 { print $1; exit }')"
  [[ "$center" =~ ^%[0-9]+$ ]] || return 0
  mapfile -t gutters < <(tmux list-panes -t "$window" -F '#{pane_id} #{@dev_workspace_agent_gutter}' |
    awk '$2 == 1 { print $1 }')

  # Keep the central pane near 60 columns or wider.
  if ((width < min_width)); then
    for gutter in "${gutters[@]}"; do
      tmux kill-pane -t "$gutter"
    done
    tmux select-pane -t "$center"
    return 0
  fi

  if ((${#gutters[@]} != 2)); then
    for gutter in "${gutters[@]}"; do
      tmux kill-pane -t "$gutter"
    done
    gutters=()
    gutters+=("$(tmux split-window -h -b -l 20% -P -F '#{pane_id}' -t "$center" 'exec sleep infinity')")
    tmux set-option -p -t "${gutters[0]}" @dev_workspace_agent_gutter 1
    gutters+=("$(tmux split-window -h -l 25% -P -F '#{pane_id}' -t "$center" 'exec sleep infinity')")
    tmux set-option -p -t "${gutters[1]}" @dev_workspace_agent_gutter 1
    tmux select-pane -t "$center"
    return 0
  fi

  tmux resize-pane -t "${gutters[0]}" -x 20% 2>/dev/null || true
  tmux resize-pane -t "${gutters[1]}" -x 20% 2>/dev/null || true
}

tmux-agent-reset-layout() {
  [[ $# == 1 && "$1" =~ ^%[0-9]+$ ]] || return 1

  local center="$1"
  local gutter
  local panes

  panes="$(tmux list-panes -t "$center" -F '#{pane_id} #{@dev_workspace_agent_gutter}')"
  while read -r gutter marker; do
    [[ "$marker" == 1 && "$gutter" =~ ^%[0-9]+$ ]] || continue
    tmux kill-pane -t "$gutter"
  done <<<"$panes"
  tmux set-option -p -u -t "$center" @dev_workspace_agent_center 2>/dev/null || true
  tmux select-pane -t "$center"
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

  local window
  local center_pane
  for window in agent term; do
    center_pane="$(tmux list-panes -t "=$session:$window" -F '#{pane_id}' 2>/dev/null || true)"
    if [[ -n "$center_pane" && "$center_pane" != *$'\n'* ]]; then
      tmux-agent-center-layout "$center_pane"
    fi
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
    tmux set-option -t "$session" @dev_workspace_path "$dir"
    tmux-restore-layout "$dir" "$session"
    printf '%s\n' "$session"
    return
  fi

  legacy="$(tmux-legacy-session-name "$dir")"
  if [[ "$legacy" != "$session" ]] &&
    tmux has-session -t "=$legacy" 2>/dev/null &&
    tmux-session-matches-path "$legacy" "$dir"; then
    tmux set-option -t "$legacy" @dev_workspace_path "$dir"
    tmux-restore-layout "$dir" "$legacy"
    printf '%s\n' "$legacy"
    return
  fi

  layout="$(tmux-layout "$dir")"
  read -r -a names <<<"$layout"
  first="${names[0]}"
  tmux new-session -ds "$session" -n "$first" -c "$dir"
  tmux set-option -t "$session" @dev_workspace_path "$dir"

  for name in "${names[@]:1}"; do
    tmux new-window -d -t "=$session" -n "$name" -c "$dir"
  done

  tmux-restore-layout "$dir" "$session"

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
  [[ -d "$dir" ]] || {
    echo "dev-workspace: not a directory: $dir" >&2
    exit 1
  }

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

tmux-group-session-rows() {
  # Input is newest-first; the first member encountered determines group recency.
  awk -F '\t' '
    {
      for (j = 1; j <= NF; j++) rows[NR, j] = $j
      if ($8 != "" && !($8 in roots)) roots[$8] = NR
    }
    END {
      for (i = 1; i <= NR; i++) {
        path = rows[i, 8]
        sub(/\/[^/]+$/, "", path)
        if (path !~ /\/\.workspaces$/) continue
        sub(/\/\.workspaces$/, "", path)
        if (!(path in roots)) continue
        root = roots[path]
        parent[i] = root
        children[root, ++count[root]] = i
      }
      for (i = 1; i <= NR; i++) {
        root = parent[i] ? parent[i] : i
        if (root in emitted) continue
        emitted[root] = 1
        emit(root, 0)
        for (j = 1; j <= count[root]; j++)
          emit(children[root, j], 1)
      }
    }
    function emit(i, child) {
      printf "%s%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        child ? "    " : "", rows[i, 1], rows[i, 2], rows[i, 3],
        rows[i, 4], rows[i, 5], rows[i, 7], child
    }
  '
}

tmux-list-sessions() {
  local windows
  local attached
  local session
  local recorded
  local dir
  local parent
  local label
  local repo
  local owner
  local context
  local detail
  local group
  local last_attached
  local count_session
  local running_count
  local waiting_count
  local ready_count
  local idle_count
  local badge
  local -A badges=()
  local -A summaries=()
  if [[ "${1:-}" == --compact ]]; then
    while IFS=$'\t' read -r count_session running_count waiting_count ready_count idle_count; do
      [[ -n "$count_session" ]] || continue
      badge='·'
      ((running_count > 0)) && badge='⠹'
      ((ready_count > 0)) && badge='◆'
      ((waiting_count > 0)) && badge='?'
      badges["$count_session"]="$badge"
      summaries["$count_session"]="$running_count running · $waiting_count waiting · $ready_count ready · $idle_count idle"
    done < <(agent-session-counts)
  fi

  while IFS=$'\t' read -r windows attached session recorded dir last_attached; do
    [[ -n "$session" ]] || continue
    if [[ "${1:-}" == --compact ]]; then
      label="$session"
      context=' '
      detail="${dir:-$session}"
      group=''
      if [[ -n "$dir" && ("$recorded" == 1 || ("$session" != main && "$dir" == "$DEV_ROOT"/*)) ]]; then
        dir="${dir%/}"
        group="$dir"
        label="${dir##*/}"
        context="$(path-context "$dir")"
        parent="${dir%/*}"
        if [[ "${parent##*/}" == .workspaces ]]; then
          repo="${parent%/*}"
          context="${repo##*/}/.workspaces"
        fi
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$context" "$session" "$detail" \
        "${badges[$session]:- }" "$last_attached" "${summaries[$session]:-No agents}" "$group"
      continue
    fi
    if [[ "$recorded" != 1 && ("$session" == main || "$dir" != "$DEV_ROOT"/*) ]]; then
      printf '%s\t%s\t%s\t%s\t%s\n' "$windows" "$attached" "$session" "$session" "$last_attached"
      continue
    fi

    dir="${dir%/}"
    parent="${dir%/*}"
    label="${parent##*/} / ${dir##*/}"
    if [[ "${parent##*/}" == .workspaces ]]; then
      repo="${parent%/*}"
      owner="${repo%/*}"
      label="${owner##*/} / ${repo##*/} / ${dir##*/}"
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$windows" "$attached" "$label" "$session" "$last_attached"
  done < <(tmux list-sessions -F $'#{session_windows} windows\t#{session_attached} attached\t#S\t#{?@dev_workspace_path,1,0}\t#{?@dev_workspace_path,#{@dev_workspace_path},#{pane_start_path}}\t#{session_last_attached}' 2>/dev/null || true) |
    if [[ "${1:-}" == --compact ]]; then
      LC_ALL=C sort -t $'\t' -k6,6nr -k1,1 | tmux-group-session-rows
    else
      cut -f1-4
    fi
}

tmux-session-rows() {
  local frame='⠹'
  local animate=false
  local now
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  if [[ "${1:-}" == --animate ]]; then
    animate=true
    now="$(date +%s%N)"
    frame="${frames[$((now / 80000000 % ${#frames[@]}))]}"
  fi

  # Pad project names before adding the one-column glyph; byte length is not display width.
  tmux-list-sessions --compact | format-picker-rows --preserve-order |
    awk -F '\t' -v frame="$frame" -v animate="$animate" '{
      badge = $5 == "⠹" ? frame : $5
      if (animate == "true") {
        esc=sprintf("%c", 27)
        if ($5 == "?") badge = esc "[33;1m?" esc "[0m"
        if ($5 == "◆") badge = esc "[36;1m◆" esc "[0m"
        if ($5 == "⠹") badge = esc "[32;1m" frame esc "[0m"
        if ($5 == "·") badge = esc "[90m·" esc "[0m"
      }
      prefix = badge "  "
      name = $1
      if ($7 == 1) {
        prefix = "    " badge "  "
        name = substr(name, 5)
      }
      printf "%s%s\t%s\t%s\t%s\t%s · %s\n", prefix, name, $2, $3, $4, $4, $6
    }'
}

tmux-pick-session-rofi() {
  local result
  local code
  local session

  while true; do
    result="$(tmux-session-rows | pick-lines 'session > ' tmux-sessions)" || return 0
    code="${result%%$'\t'*}"
    [[ "$code" == 11 ]] && continue
    [[ "$code" == 12 ]] && return 0
    session="$(selected-target "${result#*$'\t'}")"
    [[ -n "$session" ]] || return 0

    case "$code" in
      0)
        tmux-switch-session "$session"
        return
        ;;
      10)
        tmux kill-session -t "=$session"
        continue
        ;;
      *) return 0 ;;
    esac
  done
}

tmux-pick-session-fzf() {
  local selection
  local session
  local command

  command="DEV_WORKSPACE_BACKEND=tmux dev-workspace list-sessions --compact --animate"
  selection="$(tmux-session-rows --animate |
    pick-lines 'session > ' tmux-sessions "$command" 'tmux kill-session -t "="{3}')" || return 0

  [[ -n "$selection" ]] || return 0
  session="$(selected-target "$selection")"
  tmux-switch-session "$session"
}

tmux-pick-session() {
  require tmux

  case "$(picker)" in
    rofi) tmux-pick-session-rofi ;;
    fzf)
      require fzf
      tmux-pick-session-fzf
      ;;
  esac
}

tmux-picker-popup() {
  [[ $# == 3 ]] || return 1

  local action="$1"
  local pane="$2"
  local client_width="$3"
  local width

  [[ "$pane" =~ ^%[0-9]+$ && "$client_width" =~ ^[1-9][0-9]*$ ]] || return 1
  case "$action" in
    project | sessions) ;;
    *) return 1 ;;
  esac

  if ((client_width < 94)); then
    width=$((client_width * 90 / 100))
  elif ((client_width < 210)); then
    width=84
  else
    width=$((client_width * 40 / 100))
  fi

  tmux display-popup -t "$pane" -B -E -w "$width" -h 70% "DEV_WORKSPACE_BACKEND=tmux DEV_WORKSPACE_FZF_HEIGHT=100% dev-workspace $action"
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
      local pane
      pane="$(tmux new-window -P -F '#{pane_id}' -c '#{pane_current_path}' -n term)"
      tmux-agent-center-layout "$pane"
      ;;
    agent)
      local pane
      pane="$(tmux new-window -P -F '#{pane_id}' -c '#{pane_current_path}' -n agent \
        'if command -v pi >/dev/null 2>&1; then pi; fi; exec ${SHELL:-sh}')"
      tmux-agent-center-layout "$pane"
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

  selection="$(tmux list-windows -F $'#W\t#{pane_current_command}\t#I\t#W · #{pane_current_command} · #{pane_current_path}' |
    compact-window-rows | pick-lines 'window >' windows)" || return 0
  [[ -n "$selection" ]] || return 0

  index="$(selected-target "$selection")"
  tmux select-window -t "$index"
}

tmux-dispatch() {
  case "${1:-project}" in
    project | projects) tmux-pick-project ;;
    zoxide | z) tmux-pick-zoxide ;;
    sessions | session | active) tmux-pick-session ;;
    picker-popup)
      shift
      tmux-picker-popup "$@"
      ;;
    agents | agent-overview) agent-overview ;;
    list-agents) agent-list ;;
    agent-visit)
      shift
      agent-visit "$@"
      ;;
    agent-focus)
      shift
      tmux-agent-focus "$@"
      ;;
    agent-layout-resize)
      shift
      tmux-agent-resize-layout "$@"
      ;;
    agent-layout-reset)
      shift
      tmux-agent-reset-layout "$@"
      ;;
    list-sessions)
      shift
      if [[ "${1:-}" == --compact ]]; then
        shift
        tmux-session-rows "${1:-}"
        return
      fi
      tmux-list-sessions
      ;;
    windows | window | win) tmux-windows ;;
    open-path | restore-path)
      shift
      [[ $# -gt 0 ]] || {
        usage >&2
        exit 1
      }
      tmux-open-path "$1"
      ;;
    toggle | previous | back)
      require tmux
      tmux switch-client -l
      ;;
    new)
      shift
      tmux-new "${1:-term}"
      ;;
    slot)
      shift
      tmux-slot "${1:-dev}"
      ;;
    list-projects)
      shift
      list-projects "$@"
      ;;
    list-zoxide) list-zoxide ;;
    --help | -h | help) usage ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

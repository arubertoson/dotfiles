agent-status-dir() {
  printf '%s/pi-agents\n' "${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}"
}

agent-ack() {
  if [[ $# != 2 || ! "$1" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
    printf 'usage: dev-workspace agent-ack INSTANCE COMPLETION\n' >&2
    return 1
  fi

  local instance="$1"
  local completion="$2"
  local dir
  local file
  local -a fields=()

  dir="$(agent-status-dir)"
  file="$dir/$instance.status"
  [[ -f "$file" ]] || return 0
  mapfile -t fields <"$file" || return 0
  ((${#fields[@]} == 10)) || return 0
  [[ "${fields[0]}" == 1 && "${fields[1]}" == "$instance" &&
    "${fields[5]}" == ready && "${fields[7]}" == "$completion" ]] || return 0

  # The marker names the displayed completion, never whichever result finishes next.
  (
    umask 077
    mkdir -p "$dir/acknowledgments"
    : >"$dir/acknowledgments/$instance-$completion.reviewed"
  )
}

agent-visit() {
  [[ $# == 2 && -n "$1" && "$2" =~ ^%[0-9]+$ ]] || return 0

  local server="$1"
  local pane="$2"
  local dir
  local file
  local -a fields=()

  dir="$(agent-status-dir)"
  [[ -d "$dir" ]] || return 0
  for file in "$dir"/*.status; do
    [[ -f "$file" ]] || continue
    fields=()
    mapfile -t fields <"$file" || continue
    ((${#fields[@]} == 10)) || continue
    [[ "${fields[0]}" == 1 &&
      "${fields[1]}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ &&
      "${fields[2]}" =~ ^[1-9][0-9]*$ && "${fields[7]}" =~ ^[1-9][0-9]*$ &&
      "${fields[3]}" == "$pane" && "${fields[4]}" == "$server" &&
      "${fields[5]}" == ready ]] || continue
    kill -0 "${fields[2]}" 2>/dev/null || continue
    agent-ack "${fields[1]}" "${fields[7]}"
  done
}

agent-display-status() {
  local status="$1"
  local instance="$2"
  local completion="$3"

  if [[ "$status" == ready &&
    "$instance" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ &&
    "$completion" =~ ^[1-9][0-9]*$ &&
    -f "$(agent-status-dir)/acknowledgments/$instance-$completion.reviewed" ]]; then
    printf 'idle\n'
    return
  fi
  printf '%s\n' "$status"
}

agent-session-counts() {
  require tmux

  local dir
  local file
  local pane
  local server
  local session
  local pid
  local status
  local -a fields
  local current_server="${TMUX:-}"

  current_server="${current_server%,*}"
  dir="$(agent-status-dir)"
  [[ -d "$dir" ]] || return 0

  for file in "$dir"/*.status; do
    [[ -f "$file" ]] || continue
    fields=()
    mapfile -t fields <"$file"
    ((${#fields[@]} == 10)) || continue
    [[ "${fields[0]}" == 1 && "${fields[2]}" =~ ^[0-9]+$ ]] || continue
    pid="${fields[2]}"
    kill -0 "$pid" 2>/dev/null || continue

    pane="${fields[3]}"
    server="${fields[4]}"
    status="${fields[5]}"
    [[ "$status" =~ ^(idle|running|waiting|ready)$ ]] || continue
    [[ -n "$pane" && -n "$current_server" && "$server" == "$current_server" ]] || continue
    status="$(agent-display-status "$status" "${fields[1]}" "${fields[7]}")"
    session="$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null || true)"
    [[ -n "$session" ]] || continue
    printf '%s\t%s\n' "$session" "$status"
  done | awk -F '\t' '
    $2 == "running" { running[$1]++ }
    $2 == "waiting" { waiting[$1]++ }
    $2 == "ready" { ready[$1]++ }
    $2 == "idle" { idle[$1]++ }
    { sessions[$1] = 1 }
    END {
      for (session in sessions) {
        printf "%s\t%d\t%d\t%d\t%d\n", session, running[session], waiting[session], ready[session], idle[session]
      }
    }
  '

}

agent-list() {
  require tmux

  local dir
  local file
  local pane
  local server
  local target
  local context
  local age
  local pid
  local status
  local project
  local label
  local changed
  local completion
  local priority
  local -a fields
  local now
  local current_server="${TMUX:-}"

  current_server="${current_server%,*}"
  dir="$(agent-status-dir)"
  [[ -d "$dir" ]] || return 0
  now="$(date +%s)"

  for file in "$dir"/*.status; do
    [[ -f "$file" ]] || continue
    fields=()
    mapfile -t fields <"$file"
    ((${#fields[@]} == 10)) || continue
    [[ "${fields[0]}" == 1 && "${fields[2]}" =~ ^[0-9]+$ ]] || continue

    pid="${fields[2]}"
    kill -0 "$pid" 2>/dev/null || continue
    pane="${fields[3]}"
    server="${fields[4]}"
    status="${fields[5]}"
    changed="${fields[6]}"
    completion="${fields[7]}"
    project="${fields[8]}"
    label="${fields[9]}"
    [[ "$status" =~ ^(idle|running|waiting|ready)$ ]] || continue
    status="$(agent-display-status "$status" "${fields[1]}" "$completion")"
    case "$status" in
      ready) priority=1 ;;
      waiting) priority=2 ;;
      running) priority=3 ;;
      idle) priority=4 ;;
    esac
    [[ "$changed" =~ ^[0-9]+$ && "$completion" =~ ^[0-9]+$ ]] || continue

    target=-
    age=$((now - changed))
    ((age < 0)) && age=0
    context="$status · ${age}s · completion $completion"
    if [[ -n "$pane" && -n "$current_server" && "$server" == "$current_server" ]] &&
      [[ "$(tmux display-message -p -t "$pane" '#{pane_id}' 2>/dev/null || true)" == "$pane" ]]; then
      target="$pane"
    else
      context+=" · navigation unavailable"
    fi
    [[ -n "$project" ]] && context+=" · ${project##*/}"
    printf '%s\t%s\t%s\t%s\t%s\n' "$label" "$context" "$target" "$project" "$priority"
  done | LC_ALL=C sort -t $'\t' -k5,5n -k1,1 | cut -f1-4
}

agent-overview() {
  require tmux

  local selection
  local rows
  local pane
  local session
  local code

  while true; do
    rows="$(agent-list)"
    if [[ -z "$rows" ]]; then
      tmux display-message 'No live Pi sessions found'
      return 0
    fi
    selection="$(printf '%s\n' "$rows" | pick-lines 'agent >' agents \
      'DEV_WORKSPACE_BACKEND=tmux dev-workspace list-agents')" || return 0
    [[ "$(picker)" == rofi ]] || break

    code="${selection%%$'\t'*}"
    selection="${selection#*$'\t'}"
    case "$code" in
      0) break ;;
      10) continue ;;
      *) return 0 ;;
    esac
  done
  [[ -n "$selection" ]] || return 0
  pane="$(selected-target "$selection")"
  if [[ "$pane" == - ]]; then
    tmux display-message 'This Pi session is not reachable in the current tmux server'
    return 0
  fi

  session="$(tmux display-message -p -t "$pane" '#{session_id}' 2>/dev/null || true)"
  [[ -n "$session" ]] || {
    tmux display-message 'The Pi pane is no longer available'
    return 0
  }

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
    tmux select-window -t "$pane"
    tmux select-pane -t "$pane"
    return
  fi
  tmux attach-session -t "$session"
}

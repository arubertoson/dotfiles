# Pane IDs are ordered by creation, independently of their current screen position.
tmux-real-panes() {
  tmux list-panes -t "$1" -F '#{pane_id} #{@dev_workspace_agent_gutter}' |
    awk '$2 != 1 { print $1 }' | sort -t '%' -k2,2n
}

tmux-pane-cell() {
  printf '%sx%s,%s,%s,%s' "$1" "$2" "$3" "$4" "${5#%}"
}

tmux-pane-stack() {
  local y="$4"
  local top=$((($2 - 1) / 2))
  printf '%sx%s,%s,%s[%s,%s]' "$1" "$2" "$3" "$4" \
    "$(tmux-pane-cell "$1" "$top" "$3" "$4" "$5")" \
    "$(tmux-pane-cell "$1" "$(($2 - top - 1))" "$3" "$((y + top + 1))" "$6")"
}

tmux-pane-render() {
  local window="$1"
  local width height zoomed active gutter pane layout body left right
  local size offset checksum=0 byte i j swapped
  local -a panes=() gutters=() order=() current=()
  # The editor window owns its layout, even when no editor is currently running.
  [[ "$(tmux display-message -p -t "$window" '#{window_name}')" != dev ]] || return 0

  if [[ "$(tmux show-options -wqv -t "$window" @dev_workspace_panes)" != 1 ]]; then
    # Adopt windows centered before this version, without requiring a restart.
    tmux list-panes -t "$window" -F '#{@dev_workspace_agent_center}' | grep -qx 1 || return 0
    tmux set-option -w -t "$window" @dev_workspace_panes 1
  fi
  read -r width height zoomed active < <(
    tmux display-message -p -t "$window" '#{window_width} #{window_height} #{window_zoomed_flag} #{pane_id}'
  )
  [[ "$zoomed" != 1 ]] || return 0
  mapfile -t panes < <(tmux-real-panes "$window")
  (("${#panes[@]}" <= 4)) || return 0
  mapfile -t gutters < <(tmux list-panes -t "$window" -F '#{pane_id} #{@dev_workspace_agent_gutter}' |
    awk '$2 == 1 { print $1 }')
  # A normal exit of the last shell cannot be refused; do not leave sleepers behind.
  if (("${#panes[@]}" == 0)); then
    for pane in "${gutters[@]}"; do
      tmux kill-pane -t "$pane"
    done
    return 0
  fi

  gutter=0
  if (("${#panes[@]}" <= 2 && width >= 124)); then
    gutter=$(((width - 122) / 2))
    ((gutter <= width / 5)) || gutter=$((width / 5))
  fi
  if ((gutter == 0 || ${#gutters[@]} != 2)); then
    for pane in "${gutters[@]}"; do
      tmux kill-pane -t "$pane"
    done
    gutters=()
  fi
  if ((gutter > 0 && ${#gutters[@]} == 0)); then
    for i in 1 2; do
      pane="$(tmux split-window -d -h -l 1 -t "${panes[0]}" -P -F '#{pane_id}' 'exec sleep infinity')"
      tmux set-option -p -t "$pane" @dev_workspace_agent_gutter 1
      gutters+=("$pane")
    done
  fi

  size="$width"
  offset=0
  if ((gutter > 0)); then
    size=$((width - 2 * gutter - 2))
    offset=$((gutter + 1))
  fi
  case "${#panes[@]}" in
    1) body="$(tmux-pane-cell "$size" "$height" "$offset" 0 "${panes[0]}")" ;;
    2) body="$(tmux-pane-stack "$size" "$height" "$offset" 0 "${panes[0]}" "${panes[1]}")" ;;
    3 | 4)
      size=$(((width - 1) / 2))
      offset=$((size + 1))
      left="$(tmux-pane-cell "$size" "$height" 0 0 "${panes[2]}")"
      if (("${#panes[@]}" == 4)); then
        left="$(tmux-pane-stack "$size" "$height" 0 0 "${panes[2]}" "${panes[3]}")"
      fi
      right="$(tmux-pane-stack "$((width - offset))" "$height" "$offset" 0 "${panes[0]}" "${panes[1]}")"
      body="${width}x${height},0,0{${left},${right}}"
      ;;
  esac
  if ((gutter > 0)); then
    left="$(tmux-pane-cell "$gutter" "$height" 0 0 "${gutters[0]}")"
    right="$(tmux-pane-cell "$gutter" "$height" "$((width - gutter))" 0 "${gutters[1]}")"
    body="${width}x${height},0,0{${left},${body},${right}}"
  fi

  order=("${panes[@]}")
  if (("${#panes[@]}" >= 3)); then
    order=("${panes[@]:2}" "${panes[@]:0:2}")
  fi
  if ((gutter > 0)); then
    order=("${gutters[0]}" "${order[@]}" "${gutters[1]}")
  fi
  # select-layout ignores the encoded IDs and assigns panes in index order.
  mapfile -t current < <(tmux list-panes -t "$window" -F '#{pane_id}')
  for ((i = 0; i < ${#order[@]}; i++)); do
    [[ "${current[i]}" != "${order[i]}" ]] || continue
    for ((j = i + 1; j < ${#current[@]}; j++)); do
      [[ "${current[j]}" == "${order[i]}" ]] || continue
      tmux swap-pane -d -s "${current[j]}" -t "${current[i]}"
      swapped="${current[i]}"
      current[i]="${current[j]}"
      current[j]="$swapped"
      break
    done
  done

  # tmux's custom layout format requires a rotating 16-bit checksum.
  for ((i = 0; i < ${#body}; i++)); do
    printf -v byte '%d' "'${body:i:1}"
    checksum=$(((((checksum >> 1) | ((checksum & 1) << 15)) + byte) & 65535))
  done
  printf -v layout '%04x,%s' "$checksum" "$body"
  tmux select-layout -t "$window" "$layout" >/dev/null
  # Reassert a surviving real focus if tmux selected a gutter during removal.
  if ! printf '%s\n' "${panes[@]}" | grep -Fxq -- "$active"; then
    active="${panes[0]}"
  fi
  tmux select-pane -t "$active"
}

tmux-pane-navigate() {
  local pane="$1"
  local direction="$2"
  local target
  case "$direction" in left | right | up | down | next | previous) ;; *) return 1 ;; esac
  target="$(tmux list-panes -t "$pane" \
    -F '#{pane_id} #{@dev_workspace_agent_gutter}x #{pane_left} #{pane_top} #{pane_width} #{pane_height}' |
    awk -v pane="$pane" -v direction="$direction" '
      $2 != "1x" { id[++n]=$1; x[n]=$3; y[n]=$4; w[n]=$5; h[n]=$6; if ($1==pane) a=n }
      END {
        if (!a) exit
        if (direction=="next") { print id[a % n + 1]; exit }
        if (direction=="previous") { print id[(a + n - 2) % n + 1]; exit }
        best=1e9
        for (i=1; i<=n; i++) {
          distance=0
          if (direction=="left" && x[i]+w[i]<=x[a] && y[i]<y[a]+h[a] && y[a]<y[i]+h[i])
            distance=x[a]-x[i]-w[i]+1
          if (direction=="right" && x[i]>=x[a]+w[a] && y[i]<y[a]+h[a] && y[a]<y[i]+h[i])
            distance=x[i]-x[a]-w[a]+1
          if (direction=="up" && y[i]+h[i]<=y[a] && x[i]<x[a]+w[a] && x[a]<x[i]+w[i])
            distance=y[a]-y[i]-h[i]+1
          if (direction=="down" && y[i]>=y[a]+h[a] && x[i]<x[a]+w[a] && x[a]<x[i]+w[i])
            distance=y[i]-y[a]-h[a]+1
          if (distance>0 && distance<best) { best=distance; target=id[i] }
        }
        if (target!="") print target
      }')"
  [[ -z "$target" ]] || tmux select-pane -t "$target"
}

tmux-pane-check-add() {
  local command
  command="$(tmux display-message -p -t "$1" '#{pane_current_command}')"
  if (($3 >= 4)); then
    printf 'dev-workspace: four-pane limit reached\n' >&2
    return 2
  fi
  if [[ "$(tmux display-message -p -t "$2" '#{window_name}')" == dev ||
  "${command##*/}" == nvim ]]; then
    printf 'dev-workspace: this pane is manually managed\n' >&2
    return 2
  fi
}

# Server-scoped locking also covers hooks and works on remote tmux servers.
tmux-pane-action() (
  local action="${1:-layout}"
  local pane="${2:-}"
  local window lock path created command
  local -a launch=()
  local -a panes=()
  if [[ "$action" == run ]]; then
    [[ $# -ge 4 && -d "$3" && -n "$4" ]] || {
      printf 'usage: dev-workspace pane-run PANE DIRECTORY COMMAND [ARG...]\n' >&2
      return 2
    }
  fi
  [[ -n "$pane" ]] || pane="$(tmux display-message -p '#{pane_id}')"
  [[ "$pane" =~ ^(%|@)[0-9]+$ ]] || return 1
  window="$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null)" || {
    [[ "$action" == layout ]] && return 0
    printf 'dev-workspace: source pane is no longer available\n' >&2
    return 2
  }
  [[ "$window" =~ ^@[0-9]+$ ]] || return 2
  lock="dev-workspace-panes-${window}"
  tmux wait-for -L "$lock"
  trap 'tmux wait-for -U "$lock" 2>/dev/null || true' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  # A queued hook may refer to a window which has since been closed.
  if ! tmux list-panes -t "$window" >/dev/null 2>&1; then
    [[ "$action" == layout ]] && return 0
    printf 'dev-workspace: source window is no longer available\n' >&2
    return 2
  fi

  if [[ "$action" == layout ]]; then
    tmux-pane-render "$window"
    return
  fi
  [[ "$pane" == %* ]] || return 1
  if [[ "$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null)" != "$window" ]]; then
    printf 'dev-workspace: source pane moved or closed\n' >&2
    return 2
  fi
  if [[ "$(tmux display-message -p -t "$pane" '#{@dev_workspace_agent_gutter}')" == 1 ]]; then
    [[ "$action" == can-add || "$action" == run ]] && return 2
    return 0
  fi
  mapfile -t panes < <(tmux-real-panes "$window")
  case "$action" in
    navigate)
      [[ $# == 3 ]] || return 1
      tmux-pane-navigate "$pane" "$3"
      return
      ;;
    add | can-add | run)
      if [[ "$action" == add ]]; then
        tmux-pane-check-add "$pane" "$window" "${#panes[@]}" 2>/dev/null || return 0
      fi
      if [[ "$action" != add ]]; then
        tmux-pane-check-add "$pane" "$window" "${#panes[@]}" || return 2
      fi
      [[ "$action" != can-add ]] || return 0
      if [[ "$action" == run ]]; then
        path="$3"
        launch=("${@:4}")
      fi
      if [[ "$action" == add ]]; then
        command="$(tmux display-message -p -t "$pane" '#{pane_current_command}')"
        [[ "${command##*/}" != pi ]] || launch=('exec pi')
        path="$(tmux display-message -p -t "$pane" '#{pane_current_path}')"
      fi
      # Use the full window before splitting a possibly zoomed pane.
      if [[ "$(tmux display-message -p -t "$pane" '#{window_zoomed_flag}')" == 1 ]]; then
        tmux resize-pane -Z -t "$pane"
      fi
      created="$(tmux split-window -d -v -t "$pane" -c "$path" -P -F '#{pane_id}' "${launch[@]}")" || return 1
      tmux set-option -w -t "$window" @dev_workspace_panes 1
      tmux select-pane -t "$created"
      [[ "$action" != run ]] || printf '%s\n' "$created"
      ;;
    remove)
      (("${#panes[@]}" > 1)) || return 0
      tmux set-option -w -t "$window" @dev_workspace_panes 1
      tmux kill-pane -t "$pane"
      ;;
    *) return 1 ;;
  esac
  tmux-pane-render "$window"
)

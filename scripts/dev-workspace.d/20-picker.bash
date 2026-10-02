picker() {
  if [[ -n "${DEV_WORKSPACE_PICKER:-}" ]]; then
    printf '%s\n' "$DEV_WORKSPACE_PICKER"
    return
  fi

  if [[ "$(backend)" == niri ]]; then
    printf '%s\n' rofi
    return
  fi

  printf '%s\n' fzf
}

list-zoxide() {
  local dir
  local label

  command -v zoxide >/dev/null 2>&1 || return 0

  zoxide query -l 2>/dev/null | while IFS= read -r dir; do
    [[ -d "$dir" ]] || continue
    dir="$(canonical-path "$dir")"
    label="$(pretty-path "$dir")"
    printf 'zoxide\t%s\t%s\n' "$label" "$dir"
  done
}

format-picker-rows() {
  local max=32
  local preserve_order=false

  if [[ "${1:-}" == --preserve-order ]]; then
    preserve_order=true
  else
    max="${1:-32}"
  fi

  if [[ "$preserve_order" == true ]]; then
    format-picker-rows-render "$max"
    return
  fi

  LC_ALL=C sort -f -t $'\t' -k1,1 -k2,2 | format-picker-rows-render "$max"
}

format-picker-rows-render() {
  local max="${1:-32}"

  # Display columns may change; target and optional preview fields must not.
  awk -F '\t' -v max="$max" '
    { rows[NR] = $0; names[NR] = $1
      if (length($1) > width) width = length($1) }
    END {
      if (width > max) width = max
      for (i = 1; i <= NR; i++) {
        printf "%-*s", width, names[i]
        count = split(rows[i], fields, "\t")
        for (j = 2; j <= count; j++) printf "\t%s", fields[j]
        printf "\n"
      }
    }
  '
}

compact-window-rows() {
  local row
  local title

  while IFS= read -r row; do
    title="${row%%$'\t'*}"
    if ((${#title} > 40)); then
      title="${title:0:39}…"
    fi
    printf '%s\t%s\n' "$title" "${row#*$'\t'}"
  done | format-picker-rows 40
}

pick-lines() {
  local prompt="$1"
  local mode="${2:-normal}"
  local reload="${3:-}"
  local delete="${4:-}"
  local choice
  local code=0
  local bind=()
  local options=()
  local header
  local title
  local preview
  local preview_window='down,3,wrap'
  local path
  local path_field
  local sessions=false
  local footer
  local sort=(-sort)

  if [[ "$mode" == tmux-sessions ]]; then
    mode=custom-delete
    sessions=true
  fi

  case "$mode" in
    custom-refresh)
      bind+=(--bind 'ctrl-y:execute-silent(dev-workspace yank-path {3})+abort')
      ;;
    custom-delete)
      bind+=(--bind 'ctrl-y:execute-silent(dev-workspace yank-path {4})+abort')
      ;;
  esac

  case "$mode" in
    custom-refresh)
      header='enter: open · ctrl-y: copy path · ctrl-r: refresh · esc: cancel'
      title=' Projects '
      preview="printf '%s\\n' {3}"
      reload='dev-workspace list-projects --compact --refresh'
      ;;
    custom-delete)
      header='enter: switch · ctrl-y: copy path · ctrl-d: kill · ctrl-r: refresh · esc: cancel'
      title=' Workspaces '
      preview="printf '%s\\n' {4}"
      ;;
    agents)
      header='enter: visit and review · ctrl-r: refresh · esc: cancel'
      title=' Agents '
      preview="printf '%s\\n' {4}"
      sort=(-no-sort)
      ;;
    windows)
      header='enter: focus · esc: cancel'
      title=' Windows '
      preview="printf '%s\\n' {4}"
      ;;
  esac

  if [[ "$sessions" == true ]]; then
    title=' Sessions '
    sort=(-no-sort)
    header=''
    preview=''
    footer='enter switch · ctrl-d kill · ctrl-y copy path · ctrl-r refresh · esc cancel'
  fi

  case "$(picker)" in
    rofi)
      require rofi
      if [[ "$sessions" == true ]]; then
        header='enter: switch · ctrl-d: kill · ctrl-y: copy path · ctrl-r: refresh · esc: cancel'
      fi
      if [[ "$mode" != normal ]]; then
        options=(-no-custom -display-columns '1,2' -column-separator '\t' -mesg "$header")
      fi
      case "$mode" in
        agents) bind=(-kb-custom-1 Control+r) ;;
        custom-delete) bind=(-kb-custom-1 Control+d -kb-custom-2 Control+r -kb-custom-3 Control+y) ;;
        custom-refresh) bind=(-kb-custom-1 Control+r -kb-custom-2 Control+y) ;;
      esac
      choice="$(rofi -dmenu -i -matching fuzzy "${sort[@]}" -theme "$ROFI_THEME" \
        -p "$prompt" "${bind[@]}" "${options[@]}")" || code=$?
      if [[ "$mode" == custom-delete || "$mode" == custom-refresh || "$mode" == agents ]]; then
        case "$mode:$code" in
          custom-delete:12) path_field=4 ;;
          custom-refresh:11) path_field=3 ;;
          *) path_field= ;;
        esac
        if [[ -n "$path_field" && -n "$choice" ]]; then
          path="$(awk -F '\t' -v field="$path_field" '{print $field}' <<<"$choice")"
          dev-workspace yank-path "$path"
        fi
        printf '%s\t%s\n' "$code" "$choice"
        return
      fi
      [[ "$code" == 0 ]] || return 1
      printf '%s\n' "$choice"
      ;;
    fzf)
      require fzf
      if [[ "$mode" != normal ]]; then
        options=(--height="${DEV_WORKSPACE_FZF_HEIGHT:-~20}"
          --nth=1,2 --highlight-line --border-label="$title")
        if [[ "$mode" == custom-refresh || "$sessions" == true ]]; then
          options+=(--margin=0,0)
        fi
        if [[ "$mode" == custom-refresh ]]; then
          options+=(--no-scrollbar --pointer='' --footer='enter open · ctrl-y path · ctrl-r refresh · esc cancel')
        else
          [[ -n "$header" ]] && options+=(--header="$header")
          if [[ -n "$preview" ]]; then
            options+=(--preview="$preview" --preview-window="$preview_window")
          fi
        fi
      fi
      if [[ "$sessions" == true ]]; then
        options+=(--tiebreak=index --no-scrollbar --pointer='' --preview-window=hidden
          --footer="$footer" --no-info --no-sort)
        # fzf owns this refresh chain and cancels it on exit; synchronous reloads
        # retain the visible list and cursor position while the next frame is read.
        [[ -n "$reload" ]] && bind+=(--bind "load:reload-sync(sleep 0.08; $reload)")
      fi
      [[ "$mode" == agents ]] && options+=(--tiebreak=index)
      if [[ -n "$reload" ]]; then
        bind+=(--bind "ctrl-r:reload($reload)+clear-query")
      fi
      if [[ -n "$delete" ]]; then
        bind+=(--bind "ctrl-d:execute-silent($delete)+reload($reload)+clear-query")
      fi
      FZF_DEFAULT_OPTS="$FZF_OPTS" \
        fzf --ansi --no-hscroll --height="$FZF_HEIGHT" --layout=reverse --border \
        --delimiter=$'\t' --with-nth=1,2 --prompt="$prompt" "${bind[@]}" "${options[@]}"
      ;;
    *)
      echo "dev-workspace: unknown picker: $(picker)" >&2
      exit 1
      ;;
  esac
}

selected-path() {
  printf '%s\n' "${1##*$'\t'}"
}

selected-target() {
  local rest="${1#*$'\t'}"

  rest="${rest#*$'\t'}"
  printf '%s\n' "${rest%%$'\t'*}"
}

pick-project-path() {
  local result
  local code
  local selection

  while true; do
    result="$(list-projects --compact |
      pick-lines 'find project > ' custom-refresh)" || return 0

    if [[ "$(picker)" != rofi ]]; then
      selection="$result"
      break
    fi

    code="${result%%$'\t'*}"
    selection="${result#*$'\t'}"

    case "$code" in
      0) break ;;
      10)
        write-project-cache
        continue
        ;;
      11) return 0 ;;
      *) return 0 ;;
    esac
  done

  [[ -n "$selection" ]] || return 0
  selected-target "$selection"
}

pick-zoxide-path() {
  local selection

  selection="$(list-zoxide | awk -F '\t' '{print $2 "\t" $3}' |
    pick-lines 'zoxide >')" || return 0
  [[ -n "$selection" ]] || return 0

  selected-target "$selection"
}

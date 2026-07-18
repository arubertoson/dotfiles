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

pick-lines() {
  local prompt="$1"
  local mode="${2:-normal}"
  local choice
  local code=0
  local bind=()
  local reload

  case "$(picker)" in
    rofi)
      require rofi
      if [[ "$mode" == custom-delete ]]; then
        choice="$(rofi -dmenu -i -matching fuzzy -sort -theme "$ROFI_THEME" \
          -p "$prompt" -kb-custom-1 Control+d)"
        code=$?
        printf '%s\t%s\n' "$code" "$choice"
        return
      fi

      if [[ "$mode" == custom-refresh ]]; then
        choice="$(rofi -dmenu -i -matching fuzzy -sort -theme "$ROFI_THEME" \
          -p "$prompt" -kb-custom-1 Control+r)" || code=$?
        printf '%s\t%s\n' "$code" "$choice"
        return
      fi

      choice="$(rofi -dmenu -i -matching fuzzy -sort -theme "$ROFI_THEME" -p "$prompt")" || return 1
      printf '%s\n' "$choice"
      ;;
    fzf)
      require fzf
      if [[ "$mode" == custom-refresh ]]; then
        reload="dev-workspace list-projects --refresh | "
        reload+="awk -F '\t' '{print \$2 \"\t\" \$3}'"
        bind=(--bind "ctrl-r:reload($reload)+clear-query")
      fi

      FZF_DEFAULT_OPTS="$FZF_OPTS" \
        fzf --ansi --no-hscroll --height="$FZF_HEIGHT" --layout=reverse --border \
          --delimiter=$'\t' --with-nth=1,2 --prompt="$prompt" "${bind[@]}"
      ;;
    *)
      echo "dev-workspace: unknown picker: $(picker)" >&2
      exit 1
      ;;
  esac
}

selected-path() {
  local selection="$1"
  local rest

  rest="${selection#*$'\t'}"
  printf '%s\n' "${rest#*$'\t'}"
}

pick-project-path() {
  local result
  local code
  local selection

  while true; do
    result="$(list-projects | awk -F '\t' '{print $2 "\t" $3}' | \
      pick-lines 'project >' custom-refresh)" || return 0

    if [[ "$(picker)" != rofi ]]; then
      selection="$result"
      break
    fi

    code="${result%%$'\t'*}"
    selection="${result#*$'\t'}"

    case "$code" in
      0) break ;;
      10) write-project-cache; continue ;;
      *) return 0 ;;
    esac
  done

  [[ -n "$selection" ]] || return 0
  selected-path "$selection"
}

pick-zoxide-path() {
  local selection

  selection="$(list-zoxide | awk -F '\t' '{print $2 "\t" $3}' | \
    pick-lines 'zoxide >')" || return 0
  [[ -n "$selection" ]] || return 0

  selected-path "$selection"
}

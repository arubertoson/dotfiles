list-zoxide() {
  local dir label

  command -v zoxide >/dev/null 2>&1 || return 0

  zoxide query -l 2>/dev/null | while IFS= read -r dir; do
    [[ -d "$dir" ]] || continue
    label="$(pretty-path "$dir")"
    print -r -- $'zoxide\t'"$label"$'\t'"$dir"
  done
}

pick-zoxide() {
  local selection

  selection="$(list-zoxide | pick-lines 'zoxide> ')"
  [[ -n "$selection" ]] || exit 0

  open-path "$(selected-path "$selection")"
}

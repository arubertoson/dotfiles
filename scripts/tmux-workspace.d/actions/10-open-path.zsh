open-path() {
  local dir="$1"
  local session

  [[ -d "$dir" ]] || dir="$(abs-path "$dir")"
  session="$(ensure-session "$dir")"
  switch-session "$session"
}

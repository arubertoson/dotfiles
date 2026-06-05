cache-fresh() {
  [[ -f "$PROJECT_CACHE" ]] || return 1

  local now mtime
  now="$(date +%s)"
  mtime="$(stat -c %Y "$PROJECT_CACHE" 2>/dev/null || true)"
  [[ -n "$mtime" ]] || return 1

  (( now - mtime < CACHE_TTL ))
}

write-project-cache() {
  local fd_cmd tmp git_dir rel dir_abs jj_dir jj_root ws_line ws_name ws_path label
  typeset -A git_seen jj_seen

  fd_cmd="$(fd-cmd)"
  mkdir -p "$CACHE_DIR"
  tmp="$PROJECT_CACHE.$$"
  : > "$tmp"

  if [[ -n "$fd_cmd" && -d "$DEV_ROOT" ]]; then
    while IFS= read -r git_dir; do
      [[ -n "$git_dir" ]] || continue

      rel="${git_dir%/.git/}"
      rel="${rel%/.git}"
      [[ -n "$rel" ]] || rel='.'
      dir_abs="$(abs-path "$rel")"
      git_seen[$dir_abs]=1
      label="$(pretty-path "$dir_abs")"
      print -r -- $'git\t'"$label"$'\t'"$dir_abs" >> "$tmp"
    done < <("$fd_cmd" -L -HI -t d '^\.git$' --base-directory "$DEV_ROOT" 2>/dev/null || true)

    if command -v jj >/dev/null 2>&1; then
      while IFS= read -r jj_dir; do
        [[ -n "$jj_dir" ]] || continue

        jj_root="$(jj workspace root -R "$(abs-path "$jj_dir")" 2>/dev/null || true)"
        [[ -n "$jj_root" ]] || continue
        [[ -z "${jj_seen[$jj_root]:-}" ]] || continue

        jj_seen[$jj_root]=1
        while IFS= read -r ws_line; do
          [[ -n "$ws_line" ]] || continue

          ws_name="${ws_line%% *}"
          ws_path="${ws_line##* }"
          dir_abs="$(abs-path "$ws_path" "$jj_root")"

          if [[ "$ws_name" == default && -n "${git_seen[$dir_abs]:-}" ]]; then
            continue
          fi

          label="$(pretty-path "$dir_abs")"
          print -r -- $'jj\t'"$label"$'\t'"$dir_abs" >> "$tmp"
        done < <(jj workspace list -R "$(abs-path "$jj_dir")" --color=never 2>/dev/null \
          | awk '{name=$1; path=$NF; print name " " path}' || true)
      done < <("$fd_cmd" -L -HI -t d '^\.jj$' --base-directory "$DEV_ROOT" 2>/dev/null || true)
    fi
  fi

  sort -u "$tmp" -o "$tmp"
  mv "$tmp" "$PROJECT_CACHE"
}

list-projects() {
  local refresh="${1:-}"

  if [[ "$refresh" == '--refresh' || ! -f "$PROJECT_CACHE" ]]; then
    write-project-cache
    cat "$PROJECT_CACHE"
    return
  fi

  cat "$PROJECT_CACHE"

  if ! cache-fresh; then
    write-project-cache >/dev/null 2>&1 &!
  fi
}

pick-project() {
  local selection reload

  reload="${(q)SCRIPT_PATH} list-projects --refresh"
  selection="$(list-projects | pick-lines 'project> ' "$reload")"
  [[ -n "$selection" ]] || exit 0

  open-path "$(selected-path "$selection")"
}

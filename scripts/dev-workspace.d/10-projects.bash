cache-fresh() {
  [[ -f "$PROJECT_CACHE" ]] || return 1

  local now
  local mtime

  now="$(date +%s)"
  mtime="$(stat -c %Y "$PROJECT_CACHE" 2>/dev/null || true)"
  [[ -n "$mtime" ]] || return 1

  ((now - mtime < CACHE_TTL))
}

write-project-cache() {
  local tmp
  local marker
  local dir
  local root
  local label
  declare -A seen=()
  declare -A repos=()

  mkdir -p "$CACHE_DIR"
  tmp="$(mktemp "$CACHE_DIR/projects.XXXXXX")"

  if [[ -d "$DEV_ROOT" ]]; then
    while IFS= read -r marker; do
      [[ -n "$marker" ]] || continue
      dir="$(canonical-path "$(dirname "$marker")")"
      [[ -d "$dir" && -z "${seen[$dir]:-}" ]] || continue

      seen[$dir]=git
      label="$(pretty-path "$dir")"
      printf 'git\t%s\t%s\n' "$label" "$dir" >>"$tmp"
    done < <(
      find "$DEV_ROOT" -mindepth 2 -maxdepth "$PROJECT_MAX_DEPTH" \
        \( -type d -name .git -print -prune \) -o \
        \( -type f -name .git -print \) 2>/dev/null
    )

    while IFS= read -r marker; do
      [[ -n "$marker" ]] || continue
      dir="$(canonical-path "$(dirname "$marker")")"

      if ! command -v jj >/dev/null 2>&1; then
        [[ -z "${seen[$dir]:-}" ]] || continue
        seen[$dir]=jj
        label="$(pretty-path "$dir")"
        printf 'jj\t%s\t%s\n' "$label" "$dir" >>"$tmp"
        continue
      fi

      root="$(jj workspace root -R "$dir" 2>/dev/null || true)"
      [[ -n "$root" ]] || continue
      root="$(canonical-path "$root")"
      [[ -z "${repos[$root]:-}" ]] || continue
      repos[$root]=1

      while IFS= read -r dir; do
        [[ -n "$dir" ]] || continue
        dir="$(canonical-path "$dir")"
        [[ -d "$dir" && -z "${seen[$dir]:-}" ]] || continue

        seen[$dir]=jj
        label="$(pretty-path "$dir")"
        printf 'jj\t%s\t%s\n' "$label" "$dir" >>"$tmp"
      done < <(
        jj workspace list -R "$root" --ignore-working-copy \
          -T 'root ++ "\n"' 2>/dev/null || true
      )
    done < <(
      find "$DEV_ROOT" -mindepth 2 -maxdepth "$PROJECT_MAX_DEPTH" \
        \( -type d -name .jj -print -prune \) -o \
        \( -type f -name .jj -print \) 2>/dev/null
    )
  fi

  sort -u "$tmp" -o "$tmp"
  mv -- "$tmp" "$PROJECT_CACHE"
}

list-projects() {
  local refresh="${1:-}"

  if [[ "$refresh" == --refresh || ! -f "$PROJECT_CACHE" ]]; then
    write-project-cache
    cat "$PROJECT_CACHE"
    return
  fi

  cat "$PROJECT_CACHE"

  if ! cache-fresh; then
    write-project-cache >/dev/null 2>&1 &
  fi
}

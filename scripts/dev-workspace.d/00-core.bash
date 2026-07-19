usage() {
  cat <<'USAGE'
usage: dev-workspace [project|zoxide|sessions|windows|toggle|cleanup]
       dev-workspace [slot SLOT|new SLOT|open-path PATH]

Environment:
  DEV_WORKSPACE_BACKEND    niri or tmux; auto-detected by default
  DEV_WORKSPACE_PICKER     rofi or fzf; backend default by default
  DEV_WORKSPACE_DEV_ROOT   project root; defaults to $XDG_DEV_HOME or ~/dev
USAGE
}

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    notify-send "dev-workspace" "Missing dependency: $1" 2>/dev/null || true
    echo "dev-workspace: missing dependency: $1" >&2
    exit 1
  fi
}

backend() {
  if [[ -n "${DEV_WORKSPACE_BACKEND:-}" ]]; then
    printf '%s\n' "$DEV_WORKSPACE_BACKEND"
    return
  fi

  if [[ -n "${NIRI_SOCKET:-}" && -z "${TMUX:-}" ]]; then
    printf '%s\n' niri
    return
  fi

  printf '%s\n' tmux
}

pretty-path() {
  local dir="$1"

  if [[ "$dir" == "$DEV_ROOT"/* ]]; then
    printf '~dev/%s\n' "${dir#"$DEV_ROOT"/}"
    return
  fi

  if [[ "$dir" == "$HOME"/* ]]; then
    printf '~/%s\n' "${dir#"$HOME"/}"
    return
  fi

  printf '%s\n' "$dir"
}

abs-path() {
  local dir="$1"
  local base="${2:-$DEV_ROOT}"

  case "$dir" in
    '~dev') printf '%s\n' "$DEV_ROOT" ;;
    '~dev/'*) printf '%s/%s\n' "$DEV_ROOT" "${dir#\~dev/}" ;;
    '~') printf '%s\n' "$HOME" ;;
    '~/'*) printf '%s/%s\n' "$HOME" "${dir#\~/}" ;;
    /*) printf '%s\n' "$dir" ;;
    *) printf '%s/%s\n' "$base" "$dir" ;;
  esac
}

canonical-path() {
  local dir="$1"

  realpath -m -- "$(abs-path "$dir")"
}

safe-name() {
  local name="$1"

  name="$(printf '%s' "$name" | sed -E \
    -e 's/[^[:alnum:]_-]+/-/g' \
    -e 's/-+/-/g' \
    -e 's/^[-_]+//' \
    -e 's/[-_]+$//')"
  printf '%s\n' "${name:-workspace}"
}

session-name() {
  local dir
  local key
  local name
  local hash
  local max=56

  dir="$(canonical-path "$1")"

  if [[ "$dir" == "$DEV_ROOT"/* ]]; then
    key="${dir#"$DEV_ROOT"/}"
  elif [[ "$dir" == "$HOME"/* ]]; then
    key="home/${dir#"$HOME"/}"
  else
    key="$dir"
  fi

  name="$(safe-name "$key")"
  if ((${#name} <= max)); then
    printf '%s\n' "$name"
    return
  fi

  hash="$(printf '%s' "$dir" | sha256sum | cut -c1-8)"
  printf '%s-%s\n' "${name:0:max-9}" "$hash"
}

workspace-name() {
  printf 'dev:%s\n' "$(session-name "$1")"
}

slot-meta() {
  local slot="${1:-dev}"

  case "$slot" in
    1 | dev | code | editor) printf 'dev\t1\n' ;;
    2 | term | terminal | shell) printf 'term\t2\n' ;;
    3 | pi | agent) printf 'agent\t3\n' ;;
    4 | serv | server) printf 'serv\t4\n' ;;
    *)
      echo "dev-workspace: unknown slot: $slot" >&2
      exit 2
      ;;
  esac
}

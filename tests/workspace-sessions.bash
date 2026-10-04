#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workspace-sessions.XXXXXX")"
REAL_TMUX="$(command -v tmux || true)"
REAL_FZF="$(command -v fzf || true)"
SERVER="dotfiles-workspace-sessions-$$"
export REAL_TMUX REAL_FZF SERVER

cleanup() {
  [[ -z "$REAL_TMUX" ]] || "$REAL_TMUX" -L "$SERVER" kill-server 2>/dev/null || true
  rm -rf -- "$TEMP"
}
trap cleanup EXIT

fail() {
  printf '[workspace-sessions] FAIL: %s\n' "$*" >&2
  exit 1
}

if [[ -z "$REAL_TMUX" ]]; then
  printf '[workspace-sessions] SKIP: tmux not installed\n'
  exit 0
fi

export HOME="$TEMP/home"
export DEV_WORKSPACE_DEV_ROOT="$HOME/dev"
export DEV_WORKSPACE_BACKEND=tmux
export DEV_WORKSPACE_FZF_DEFAULT_OPTS='--sort'
export XDG_RUNTIME_DIR="$TEMP/runtime"
export XDG_STATE_HOME="$TEMP/state"
export MISE_SHIMS="$TEMP/no-shims"
unset TMUX DEV_WORKSPACE_FZF_HEIGHT
mkdir -p "$TEMP/bin" "$XDG_RUNTIME_DIR"

# Use real sessions on a private server, never the developers active server or state.
cat >"$TEMP/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "$REAL_TMUX" -L "$SERVER" -f /dev/null "$@"
EOF
chmod +x "$TEMP/bin/tmux"
export PATH="$TEMP/bin:$PATH"
source "$ROOT/scripts/dev-workspace" help >/dev/null

ALPHA="$DEV_ROOT/home/github.com/alpha/job-search"
BETA="$DEV_ROOT/home/github.com/beta/job-search"

create-session() {
  local session="$1"
  local dir="$2"
  mkdir -p "$dir"
  tmux new-session -d -s "$session" -c "$dir" 'sleep 120'
  [[ "${3:-record}" != record ]] || tmux set-option -t "$session" @dev_workspace_path "$dir"
}

create-session repo-alpha "$ALPHA/"
create-session scraper-alpha "$ALPHA/.workspaces/impl-scraper-service"
create-session document-alpha "$ALPHA/.workspaces/impl-document analysis"
create-session repo-beta "$BETA"
create-session scraper-beta "$BETA/.workspaces/impl-scraper-service"
create-session dotfiles "$DEV_ROOT/home/github.com/alpha/dotfiles"
create-session orphan "$DEV_ROOT/home/github.com/orphan/no-session/.workspaces/lone"
create-session main "$ALPHA" unrecorded
create-session notes "$ALPHA/notes"

# Only this child has an attachment timestamp; its repo group must move first.
tmux -C attach-session -t '=scraper-alpha' <<<'detach-client' >/dev/null

rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
expected=$'repo-alpha\nscraper-alpha\ndocument-alpha\ndotfiles\nrepo-beta\nscraper-beta\norphan\nmain\nnotes'
[[ "$(cut -f3 <<<"$rows")" == "$expected" ]] || fail 'repo grouping or group/child recency is wrong'
[[ "$(awk -F '\t' '$3 == "scraper-alpha" {print $1}' <<<"$rows")" == '       impl-scraper-service'* ]] ||
  fail 'the first child is not indented or lost its name'
[[ "$(awk -F '\t' '$3 == "document-alpha" {print $1}' <<<"$rows")" == '       impl-document analysis'* ]] ||
  fail 'the last child is not indented or lost its spaced name'
[[ "$(awk -F '\t' '$3 == "scraper-beta" {print $1}' <<<"$rows")" == '       impl-scraper-service'* ]] ||
  fail 'duplicate repo names were merged across paths'
for session in repo-alpha dotfiles orphan main notes; do
  label="$(awk -F '\t' -v target="$session" '$3 == target {print $1}' <<<"$rows")"
  [[ "$label" == '   '* && "$label" != '       '* ]] || fail "$session was incorrectly nested"
done
selection="$(awk -F '\t' '$3 == "document-alpha"' <<<"$rows")"
[[ "$(selected-target "$selection")" == document-alpha ]] || fail 'a child lost its switch/kill target'
[[ "$(cut -f4 <<<"$selection")" == "$ALPHA/.workspaces/impl-document analysis" ]] ||
  fail 'a child lost its copy-path target'
[[ "$(awk -F '\t' '$3 == "document-alpha" {print $2}' <<<"$rows")" == job-search/.workspaces ]] ||
  fail 'the workspace context is missing'
[[ "$(awk -F '\t' '{print NF}' <<<"$rows" | sort -u)" == 5 ]] || fail 'compact public TSV fields changed'

legacy="$("$ROOT/scripts/dev-workspace" list-sessions)"
[[ "$(awk -F '\t' '$4 == "scraper-alpha" {print $3}' <<<"$legacy")" == 'alpha / job-search / impl-scraper-service' ]] ||
  fail 'noncompact session labels changed'

if [[ -n "$REAL_FZF" ]]; then
  cat >"$TEMP/bin/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$PICKER_ARGS"
# Sync avoids the filter fast path returning only --with-nth display fields.
exec "$REAL_FZF" "$@" --sync --filter="$PICKER_QUERY"
EOF
  chmod +x "$TEMP/bin/fzf"
  export DEV_WORKSPACE_PICKER=fzf
  export PICKER_ARGS="$TEMP/picker-args"
  export PICKER_QUERY=''
  filtered="$(printf '%s\n' "$rows" | pick-lines 'session > ' tmux-sessions)"
  [[ "$(cut -f3 <<<"$filtered")" == "$expected" ]] || fail 'fzf reordered the tree'
  grep -Fxq -- '--no-sort' "$PICKER_ARGS" || fail 'fzf does not preserve tree order'
  export PICKER_QUERY='document analysis'
  filtered="$(printf '%s\n' "$rows" | pick-lines 'session > ' tmux-sessions)"
  [[ "$(selected-target "$filtered")" == document-alpha ]] || fail 'fzf cannot select a child without its parent'
fi

cat >"$TEMP/bin/rofi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$PICKER_ARGS"
awk -F '\t' '$3 == "document-alpha"'
EOF
chmod +x "$TEMP/bin/rofi"
export DEV_WORKSPACE_PICKER=rofi
export PICKER_ARGS="$TEMP/picker-args"
filtered="$(printf '%s\n' "$rows" | pick-lines 'session > ' tmux-sessions)"
grep -Fxq -- '-no-sort' "$PICKER_ARGS" || fail 'rofi does not preserve tree order'
[[ "$(selected-target "${filtered#*$'\t'}")" == document-alpha ]] || fail 'rofi cannot select a child'

# Killing the repo leaves its children as ordinary selectable rows.
tmux kill-session -t '=repo-alpha'
rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
[[ "$(cut -f3 <<<"$rows" | head -n1)" == scraper-alpha ]] || fail 'orphaned children lost their recency'
[[ "$(awk -F '\t' '$3 == "scraper-alpha" {print $1}' <<<"$rows")" == '   impl-scraper-service'* ]] ||
  fail 'a missing repo still nests its children'
[[ "$(wc -l <<<"$rows")" == 8 ]] || fail 'killing a repo also removed child rows'

tmux new-session -d -s agent-layout -x 160 -y 40 'sleep 120'
agent_pane="$(tmux display-message -p -t agent-layout '#{pane_id}')"
tmux-agent-center-layout "$agent_pane"
[[ "$(tmux list-panes -t agent-layout -F '#{pane_id}' | wc -l)" == 3 ]] || fail 'agent layout did not create two gutters'
[[ "$(tmux display-message -p -t agent-layout '#{pane_id}')" == "$agent_pane" ]] || fail 'Pi pane identity changed'
[[ "$(tmux display-message -p -t agent-layout '#{pane_current_command}')" == sleep ]] || fail 'Pi process was replaced'
left_gutter="$(tmux list-panes -t agent-layout -F '#{pane_id} #{@dev_workspace_agent_gutter}' | awk '$2 == 1 { print $1; exit }')"
[[ "$left_gutter" =~ ^%[0-9]+$ ]] || fail 'gutter marker is missing'
tmux-agent-focus "$left_gutter"
[[ "$(tmux display-message -p -t agent-layout '#{pane_id}')" == "$agent_pane" ]] || fail 'gutter focus was not redirected to Pi'
tmux-agent-center-layout "$agent_pane"
[[ "$(tmux list-panes -t agent-layout -F '#{pane_id}' | wc -l)" == 3 ]] || fail 'agent layout is not idempotent'
tmux-agent-reset-layout "$agent_pane"
[[ "$(tmux list-panes -t agent-layout -F '#{pane_id}' | wc -l)" == 1 ]] || fail 'agent layout reset did not remove gutters'
[[ "$(tmux display-message -p -t agent-layout '#{pane_id}')" == "$agent_pane" ]] || fail 'agent layout reset removed the Pi pane'

term_dir="$DEV_ROOT/term-layout"
mkdir -p "$term_dir"
tmux new-session -d -s term-layout -n dev -c "$term_dir" 'sleep 120'
tmux new-window -d -t term-layout -n term -c "$term_dir" 'sleep 120'
term_pane="$(tmux display-message -p -t term-layout:term '#{pane_id}')"
tmux-restore-layout "$term_dir" term-layout
[[ "$(tmux list-panes -t term-layout:term -F '#{pane_id}' | wc -l)" == 3 ]] || fail 'term window did not get centered gutters'
[[ "$(tmux display-message -p -t "$term_pane" '#{pane_current_command}')" == sleep ]] || fail 'term process was replaced'
tmux-agent-reset-layout "$term_pane"
[[ "$(tmux list-panes -t term-layout:term -F '#{pane_id}' | wc -l)" == 1 ]] || fail 'term layout reset did not remove gutters'

printf '[workspace-sessions] OK\n'
if [[ -z "$REAL_FZF" ]]; then
  printf '[workspace-sessions] SKIP: fzf checks (fzf not installed)\n'
fi

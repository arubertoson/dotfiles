#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workspace-agents.XXXXXX")"
REAL_TMUX="$(command -v tmux || true)"
REAL_FZF="$(command -v fzf || true)"
SERVER="dotfiles-workspace-agents-$$"
export REAL_TMUX REAL_FZF SERVER

cleanup() {
  [[ -z "$REAL_TMUX" ]] || "$REAL_TMUX" -L "$SERVER" kill-server 2>/dev/null || true
  rm -rf -- "$TEMP"
}
trap cleanup EXIT

fail() {
  printf '[workspace-agents] FAIL: %s\n' "$*" >&2
  if [[ -n "${window:-}" ]]; then
    tmux capture-pane -p -t "$window" >&2 || true
    [[ ! -f "${PICKER_COUNT:-}" ]] || awk '{print "match count: " $0}' "$PICKER_COUNT" >&2
  fi
  exit 1
}

if [[ -z "$REAL_TMUX" ]]; then
  printf '[workspace-agents] SKIP: tmux not installed\n'
  exit 0
fi

export HOME="$TEMP/home"
export DEV_WORKSPACE_DEV_ROOT="$HOME/dev"
export DEV_WORKSPACE_BACKEND=tmux
export XDG_RUNTIME_DIR="$TEMP/runtime"
export XDG_STATE_HOME="$TEMP/state"
export MISE_SHIMS="$TEMP/no-shims"
export DEV_WORKSPACE_FZF_DEFAULT_OPTS=''
unset TMUX TMUX_PANE FZF_DEFAULT_OPTS
mkdir -p "$TEMP/bin" "$XDG_RUNTIME_DIR/pi-agents"
cat >"$TEMP/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "$REAL_TMUX" -L "$SERVER" -f /dev/null "$@"
EOF
chmod +x "$TEMP/bin/tmux"
export PATH="$TEMP/bin:$ROOT/scripts:$PATH"
source "$ROOT/scripts/dev-workspace" help >/dev/null

REPO="$DEV_ROOT/home/github.com/team/repo"
CHILD="$REPO/.workspaces/feature"
mkdir -p "$CHILD"
tmux new-session -d -s repo -c "$REPO" 'exec sleep 120'
tmux set-option -t repo @dev_workspace_path "$REPO"
tmux new-session -d -s feature -c "$CHILD" 'exec sleep 120'
tmux set-option -t feature @dev_workspace_path "$CHILD"
tmux new-session -d -s main 'exec sleep 120'
ROOT_PANE="$(tmux new-window -d -P -F '#{pane_id}' -t '=repo' -n pi 'exec sleep 120')"
CHILD_PANE="$(tmux split-window -d -P -F '#{pane_id}' -t 'feature:' 'exec sleep 120')"
SERVER_ID="$(tmux display-message -p '#{socket_path},#{pid}')"
INSTANCE=11111111-1111-4111-8111-111111111111

register-agent() {
  local instance="$1"
  local pane="$2"
  local server="${3:-$SERVER_ID}"
  local pid="${4:-$(tmux display-message -p -t "$pane" '#{pane_pid}')}"
  # The publisher's v1 wire format, not a separate test-only registry.
  printf '%s\n' 1 "$instance" "$pid" "$pane" "$server" "${5:-ready}" "$(date +%s)" 1 "$REPO" "${6:-Shared agent label}" \
    >"$XDG_RUNTIME_DIR/pi-agents/$instance.status"
}

register-agent "$INSTANCE" "$ROOT_PANE"
register-agent 22222222-2222-4222-8222-222222222222 "$CHILD_PANE"
register-agent 33333333-3333-4333-8333-333333333333 "$ROOT_PANE" /other/server,1
register-agent 44444444-4444-4444-8444-444444444444 %999999 "$SERVER_ID" "$$"
sleep 0.01 &
dead=$!
wait "$dead"
register-agent 55555555-5555-4555-8555-555555555555 "$ROOT_PANE" "$SERVER_ID" "$dead"
printf '1\ninvalid\n' >"$XDG_RUNTIME_DIR/pi-agents/broken.status"

legacy="$("$ROOT/scripts/dev-workspace" list-sessions)"
rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
expected="$(printf 'repo\npane:%s\nfeature\npane:%s\nmain' "$ROOT_PANE" "$CHILD_PANE")"
[[ "$(cut -f3 <<<"$rows")" == "$expected" ]] || fail 'agents are not nested immediately beneath their owning sessions'
[[ "$(awk -F '\t' '{print NF}' <<<"$rows" | sort -u)" == 5 ]] || fail 'public compact TSV shape changed'
[[ "$(awk -F '\t' -v target="pane:$ROOT_PANE" '$3 == target {print $1}' <<<"$rows")" == '    ◆  Shared agent label'* ]] || fail 'repo agent indentation or ready badge is wrong'
[[ "$(awk -F '\t' -v target="pane:$CHILD_PANE" '$3 == target {print $1}' <<<"$rows")" == '        ◆  Shared agent label'* ]] || fail 'workspace agent is not nested a second level'
[[ "$(awk -F '\t' -v target="pane:$ROOT_PANE" '$3 == target {print $4}' <<<"$rows")" == "$REPO" ]] || fail 'agent copy-path target was lost'
[[ "$(wc -l <<<"$legacy")" == 3 && "$legacy" != *Shared* ]] || fail 'noncompact sessions include agent rows'
[[ "$(agent-session-counts | awk -F '\t' '$1 == "repo" {print $4}')" == 1 ]] || fail 'outside-tmux session counts did not find the current server'

# Multiple Pi instances in one workspace must own their individual indicators.
RUNNING_PANE="$(tmux new-window -d -P -F '#{pane_id}' -t '=repo' -n running 'exec sleep 120')"
WAITING_PANE="$(tmux new-window -d -P -F '#{pane_id}' -t '=repo' -n waiting 'exec sleep 120')"
IDLE_PANE="$(tmux new-window -d -P -F '#{pane_id}' -t '=repo' -n idle 'exec sleep 120')"
register-agent 66666666-6666-4666-8666-666666666666 "$RUNNING_PANE" "$SERVER_ID" "$(tmux display-message -p -t "$RUNNING_PANE" '#{pane_pid}')" running 'Running Pi'
register-agent 77777777-7777-4777-8777-777777777777 "$WAITING_PANE" "$SERVER_ID" "$(tmux display-message -p -t "$WAITING_PANE" '#{pane_pid}')" waiting 'Waiting Pi'
register-agent 88888888-8888-4888-8888-888888888888 "$IDLE_PANE" "$SERVER_ID" "$(tmux display-message -p -t "$IDLE_PANE" '#{pane_pid}')" idle 'Idle Pi'
rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
for pair in "$RUNNING_PANE:⠹:Running Pi" "$WAITING_PANE:?:Waiting Pi" "$IDLE_PANE:·:Idle Pi"; do
  pane="${pair%%:*}"
  badge="${pair#*:}"
  name="${badge#*:}"
  badge="${badge%%:*}"
  label="$(awk -F '\t' -v target="pane:$pane" '$3 == target {print $1}' <<<"$rows")"
  [[ "$label" == "    $badge  $name"* ]] || fail "$name indicator is attached to the wrong row"
done
[[ "$(awk -F '\t' -v target="pane:$ROOT_PANE" '$3 == target {print $1}' <<<"$rows")" == '    ◆  Shared agent label'* ]] || fail 'another Pi status replaced the ready indicator'
animated="$("$ROOT/scripts/dev-workspace" list-sessions --compact --animate | awk '{gsub(/\033\[[0-9;]*m/, ""); print}')"
while IFS=$'\t' read -r label context target rest; do
  if [[ "$target" != pane:* ]]; then
    [[ "$label" != *[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◆?·]* ]] || fail 'workspace row still owns an agent indicator'
    continue
  fi
  if [[ "$target" == "pane:$RUNNING_PANE" ]]; then
    [[ "$label" == '    '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]'  Running Pi'* ]] || fail 'the running Pi spinner is not animated'
    continue
  fi
  [[ "$label" != *[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]* ]] || fail 'a nonrunning Pi owns a spinner'
done <<<"$animated"

# Search must preserve ancestors without pulling in sibling agents or matching metadata.
filtered="$("$ROOT/scripts/dev-workspace" list-sessions --compact --query 'Running Pi')"
[[ "$(cut -f3 <<<"$filtered")" == "$(printf 'repo\npane:%s' "$RUNNING_PANE")" ]] || fail 'agent search lost its workspace or included unrelated agents'
filtered="$("$ROOT/scripts/dev-workspace" list-sessions --compact --query feature)"
[[ "$(cut -f3 <<<"$filtered")" == "$(printf 'repo\nfeature\npane:%s' "$CHILD_PANE")" ]] || fail 'nested workspace search lost ancestors or included sibling agents'
filtered="$("$ROOT/scripts/dev-workspace" list-sessions --compact --query repo)"
[[ "$(cut -f3 <<<"$filtered")" == "$(cut -f3 <<<"$rows" | grep -vx main)" ]] || fail 'workspace search does not preserve its full subtree and order'
# A prefix match must outrank a more recent fuzzy-only candidate.
ranked="$(printf '%s\n' \
  $'documentation\tdocumentation\tdocumentation\t/tmp/documentation\t \tNo agents\t0' \
  $'dotfiles\tdotfiles\tdotfiles\t/tmp/dotfiles\t \tNo agents\t0' |
  tmux-filter-session-rows dot)"
[[ "$(cut -f3 <<<"$ranked" | head -n1)" == dotfiles ]] || fail 'search recency outweighed a stronger prefix match'

for query in completion '120s' nonexistent; do
  [[ -z "$("$ROOT/scripts/dev-workspace" list-sessions --compact --query "$query")" ]] || fail 'status metadata matched or an empty search retained unrelated headings'
done

# These hooks match the visit acknowledgment routes in config/.tmux.conf.
tmux set-hook -g client-session-changed[50] 'run-shell -b "DEV_WORKSPACE_BACKEND=tmux dev-workspace agent-visit '\''#{socket_path},#{pid}'\'' '\''#{pane_id}'\''"'
tmux set-hook -g client-attached[50] 'run-shell -b "DEV_WORKSPACE_BACKEND=tmux dev-workspace agent-visit '\''#{socket_path},#{pid}'\'' '\''#{pane_id}'\''"'

cat >"$TEMP/bin/rofi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
input="$(cat)"
if [[ -n "${DELETE_TARGET:-}" && ! -f "$DELETE_MARKER" ]]; then
  touch "$DELETE_MARKER"
  awk -F '\t' -v target="$DELETE_TARGET" '$3 == target' <<<"$input"
  exit 10
fi
awk -F '\t' -v target="$PICKER_TARGET" '$3 == target' <<<"$input"
EOF
chmod +x "$TEMP/bin/rofi"
export DEV_WORKSPACE_PICKER=rofi
export PICKER_TARGET="pane:$ROOT_PANE"
export DELETE_TARGET="pane:$CHILD_PANE"
export DELETE_MARKER="$TEMP/rofi-deleted"

snapshot="$(tmux list-panes -a -F '#{pane_id} #{pane_pid}')"
# Start the real command in a real terminal, but with TMUX unset to take attach-session.
window="$(tmux new-window -d -P -F '#{window_id}' -t '=main' -n outside \
  -e DEV_WORKSPACE_PICKER=rofi -e PICKER_TARGET="$PICKER_TARGET" -e DELETE_TARGET="$DELETE_TARGET" -e DELETE_MARKER="$DELETE_MARKER" \
  "env -u TMUX -u TMUX_PANE '$ROOT/scripts/dev-workspace' sessions; exec sleep 120")"

wait-for() {
  local description="$1"
  shift
  for _ in {1..100}; do
    if "$@"; then return; fi
    sleep 0.05
  done
  fail "$description"
}

has-client() {
  [[ "$(tmux list-clients -F '#{session_name}')" == "$1" ]]
}

wait-for 'outside-tmux picker did not attach to the agent session' has-client repo
[[ "$(tmux display-message -p -t 'repo:' '#{pane_id}')" == "$ROOT_PANE" ]] || fail 'outside-tmux selection attached to the wrong window/pane'
tmux has-session -t '=feature' || fail 'rofi deleted an agent owning session'
[[ "$(tmux display-message -p -t "$CHILD_PANE" '#{pane_id}')" == "$CHILD_PANE" ]] || fail 'rofi deleted an agent pane'
wait-for 'attach hook did not acknowledge the visited completion' test -f "$XDG_RUNTIME_DIR/pi-agents/acknowledgments/$INSTANCE-1.reviewed"
tmux detach-client -s repo
tmux kill-window -t "$window"
[[ "$(tmux list-panes -a -F '#{pane_id} #{pane_pid}')" == "$snapshot" ]] || fail 'agent navigation created/replaced a session, window or process'

# A real attached client exercises switch-client rather than attach-session.
coproc CONTROL { exec tmux -C attach-session -t '=main' >"$TEMP/client-output"; }
client="$CONTROL_PID"
wait-for 'control client did not attach' has-client main
export TMUX="$SERVER_ID,0"
export PICKER_TARGET="pane:$CHILD_PANE"
unset DELETE_TARGET
"$ROOT/scripts/dev-workspace" sessions
wait-for 'inside-tmux picker did not switch to the owning session' has-client feature
[[ "$(tmux display-message -p -t 'feature:' '#{pane_id}')" == "$CHILD_PANE" ]] || fail 'inside-tmux selection did not select the split pane'

# An editable label or owning-session rename must never become the pane target.
tmux rename-session -t '=feature' renamed-feature
printf '%s\n' "$(head -n9 "$XDG_RUNTIME_DIR/pi-agents/22222222-2222-4222-8222-222222222222.status")" 'Renamed agent label' \
  >"$TEMP/renamed.status"
mv "$TEMP/renamed.status" "$XDG_RUNTIME_DIR/pi-agents/22222222-2222-4222-8222-222222222222.status"
rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
[[ "$rows" == *"pane:$CHILD_PANE"* && "$rows" == *'Renamed agent label'* ]] || fail 'renaming changed the stable agent target'

# Rofi deletion still removes an ordinary session, then resumes picking.
tmux new-session -d -s disposable 'exec sleep 120'
export DELETE_TARGET=disposable
export DELETE_MARKER="$TEMP/rofi-session-deleted"
"$ROOT/scripts/dev-workspace" sessions
! tmux has-session -t '=disposable' 2>/dev/null || fail 'rofi no longer deletes session rows'
unset DELETE_TARGET

# Even malformed/stale pane targets must not fall through to kill-session.
"$ROOT/scripts/dev-workspace" session-target-delete 'pane:not-a-pane'
"$ROOT/scripts/dev-workspace" session-target-delete 'pane:%999999'

if [[ -n "$REAL_FZF" ]]; then
  export DEV_WORKSPACE_PICKER=fzf
  export PICKER_QUERY='Renamed agent label'
  cat >"$TEMP/bin/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "$REAL_FZF" "$@" --sync --filter="$PICKER_QUERY"
EOF
  chmod +x "$TEMP/bin/fzf"
  selected="$(printf '%s\n' "$rows" | pick-lines 'session > ' tmux-sessions)"
  [[ "$(selected-target "$selected")" == "pane:$CHILD_PANE" ]] || fail 'fzf cannot filter an agent independently of its parent'
  tmux switch-client -t '=main'
  "$ROOT/scripts/dev-workspace" sessions
  wait-for 'fzf selection did not switch sessions' has-client renamed-feature

  # Exercise the real Ctrl+D binding, reload and Enter in fzf's terminal UI.
  cat >"$TEMP/bin/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "$REAL_FZF" "$@" --bind 'result:execute-silent(printf "%s\n" {3} > "$PICKER_FOCUS"; printf "%s\n" "$FZF_MATCH_COUNT" > "$PICKER_COUNT")' \
  --bind 'zero:execute-silent(printf "0\n" > "$PICKER_COUNT")'
EOF
  export PICKER_FOCUS="$TEMP/fzf-focus"
  export PICKER_COUNT="$TEMP/fzf-count"
  export DEV_WORKSPACE_FZF_HEIGHT=100%
  window="$(tmux new-window -d -P -F '#{window_id}' -t '=main' -n picker \
    -e PICKER_FOCUS="$PICKER_FOCUS" -e PICKER_COUNT="$PICKER_COUNT" -e DEV_WORKSPACE_PICKER=fzf -e DEV_WORKSPACE_FZF_HEIGHT=100% \
    "'$ROOT/scripts/dev-workspace' sessions; touch '$TEMP/fzf-done'; exec sleep 120")"

  focus-is() {
    [[ -f "$PICKER_FOCUS" ]] && grep -Fxq "$1" "$PICKER_FOCUS"
  }

  count-is() {
    [[ -f "$PICKER_COUNT" ]] && grep -Fxq "$1" "$PICKER_COUNT"
  }

  wait-for 'fzf did not render' test -s "$PICKER_FOCUS"
  tmux send-keys -t "$window" -l completion
  wait-for 'status text is still searchable' count-is 0
  tmux send-keys -t "$window" C-u
  wait-for 'fzf did not recover from an empty result' focus-is repo
  tmux send-keys -t "$window" -l 'Renamed agent label'
  wait-for 'fzf did not retain exactly the agent and its ancestors' count-is 3
  tmux send-keys -t "$window" Down Down
  wait-for 'fzf cannot select the filtered agent beneath its headings' focus-is "pane:$CHILD_PANE"
  tmux send-keys -t "$window" C-d
  # Ctrl+D clears the query after the safe helper and reload finish.
  wait-for 'fzf delete did not reload the sessions tree' focus-is repo
  tmux has-session -t '=renamed-feature' || fail 'fzf deleted the agent owning session'
  [[ "$(tmux display-message -p -t "$CHILD_PANE" '#{pane_id}')" == "$CHILD_PANE" ]] || fail 'fzf deleted the agent pane'
  tmux new-session -d -s disposable-fzf 'exec sleep 120'
  tmux send-keys -t "$window" C-r
  tmux send-keys -t "$window" -l disposable-fzf
  wait-for 'fzf did not filter the disposable session' focus-is disposable-fzf
  tmux send-keys -t "$window" C-d
  wait-for 'fzf session deletion did not reload' focus-is repo
  ! tmux has-session -t '=disposable-fzf' 2>/dev/null || fail 'fzf no longer deletes session rows'
  tmux send-keys -t "$window" -l 'Renamed agent label'
  wait-for 'fzf lost the tree after reload' count-is 3
  tmux send-keys -t "$window" Down Down
  wait-for 'fzf lost the agent after reload' focus-is "pane:$CHILD_PANE"
  tmux send-keys -t "$window" Enter
  wait-for 'fzf Enter did not return' test -f "$TEMP/fzf-done"
  wait-for 'fzf Enter did not switch the attached client' has-client renamed-feature
  [[ "$(tmux display-message -p -t 'renamed-feature:' '#{pane_id}')" == "$CHILD_PANE" ]] || fail 'fzf Enter did not select the agent pane'
  tmux kill-window -t "$window"

  # Load the actual Alt+W binding and send keys through a real attached client,
  # so the popup route is covered as well as the standalone picker command.
  awk '/^bind-key -n M-w / {print}' "$ROOT/config/.tmux.conf" >"$TEMP/popup.conf"
  tmux source-file "$TEMP/popup.conf"
  tmux set-environment -g PICKER_FOCUS "$PICKER_FOCUS"
  tmux set-environment -g PICKER_COUNT "$PICKER_COUNT"
  : >"$PICKER_FOCUS"
  : >"$PICKER_COUNT"
  window="$(tmux new-window -d -P -F '#{window_id}' -t '=main' -n popup-host \
    -e PICKER_FOCUS="$PICKER_FOCUS" -e PICKER_COUNT="$PICKER_COUNT" -e DEV_WORKSPACE_PICKER=fzf \
    "env -u TMUX -u TMUX_PANE tmux attach-session -t '=main'; exec sleep 120")"
  tty="$(tmux display-message -p -t "$window" '#{pane_tty}')"
  popup-client-is() {
    tmux list-clients -F '#{client_tty} #{session_name}' | grep -Fxq "$tty $1"
  }
  wait-for 'popup host did not attach' popup-client-is main
  tmux send-keys -t "$window" M-w
  wait-for 'Alt+W did not open the fzf popup' test -s "$PICKER_FOCUS"
  tmux send-keys -t "$window" -l 'Renamed agent label'
  wait-for 'Alt+W search lost workspace headings' count-is 3
  tmux send-keys -t "$window" Down Down
  wait-for 'Alt+W cannot focus the filtered agent' focus-is "pane:$CHILD_PANE"
  tmux send-keys -t "$window" Enter
  wait-for 'Alt+W did not navigate its client to the agent' popup-client-is renamed-feature
  [[ "$(tmux display-message -p -t 'renamed-feature:' '#{pane_id}')" == "$CHILD_PANE" ]] || fail 'Alt+W selected the wrong pane'
  tmux kill-window -t "$window"
fi

tmux detach-client -s renamed-feature
wait "$client" || true
tmux kill-pane -t "$ROOT_PANE"
rows="$("$ROOT/scripts/dev-workspace" list-sessions --compact)"
[[ "$rows" != *"pane:$ROOT_PANE"* ]] || fail 'a stale registered pane remained selectable'
[[ "$("$ROOT/scripts/dev-workspace" list-sessions | wc -l)" == 3 ]] || fail 'navigation or deletion altered unrelated sessions'
printf '[workspace-agents] OK\n'
if [[ -z "$REAL_FZF" ]]; then
  printf '[workspace-agents] SKIP: fzf checks (fzf not installed)\n'
fi

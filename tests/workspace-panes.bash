#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
REAL_TMUX="$(command -v tmux || true)"
if [[ -z "$REAL_TMUX" ]]; then
  printf '[workspace-panes] SKIP: tmux not installed\n'
  exit 0
fi
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workspace-panes.XXXXXX")"
SERVER="dotfiles-workspace-panes-$$"
export REAL_TMUX SERVER
cleanup() {
  "$REAL_TMUX" -L "$SERVER" kill-server 2>/dev/null || true
  rm -rf -- "$TEMP"
}
trap cleanup EXIT
fail() {
  printf '[workspace-panes] FAIL: %s\n' "$*" >&2
  exit 1
}
export HOME="$TEMP/home" XDG_STATE_HOME="$TEMP/state" XDG_RUNTIME_DIR="$TEMP/runtime"
export DEV_WORKSPACE_BACKEND=tmux MISE_SHIMS="$TEMP/no-shims"
unset TMUX TMUX_PANE
mkdir -p "$HOME" "$TEMP/bin" "$TEMP/project" "$XDG_RUNTIME_DIR"
cat >"$TEMP/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec "$REAL_TMUX" -L "$SERVER" -f /dev/null "$@"
EOF
chmod +x "$TEMP/bin/tmux"
export PATH="$TEMP/bin:$ROOT/scripts:$PATH"

workspace() {
  "$ROOT/scripts/dev-workspace" "$@"
}
value() {
  tmux display-message -p -t "$1" "#{$2}"
}
real-panes() {
  tmux list-panes -t "$WINDOW" -F '#{pane_id} #{@dev_workspace_agent_gutter}' |
    awk '$2 != 1 { print $1 }'
}
assert-layout() {
  local count="$1" gutters="$2" actual
  # Hooks are asynchronous; wait for the public geometry to converge.
  for _ in {1..100}; do
    actual="$(real-panes | wc -l)"
    if [[ "$actual" == "$count" && "$(tmux list-panes -t "$WINDOW" -F '#{@dev_workspace_agent_gutter}' | grep -c '^1$' || true)" == "$gutters" ]]; then
      return
    fi
    sleep 0.02
  done
  fail "expected $count real panes and $gutters gutters"
}
assert-focus() {
  [[ "$(value "$WINDOW" pane_id)" == "$1" ]] || fail "focus did not reach $1"
}
key() {
  local binding
  binding="$(tmux list-keys -T root "$1")"
  if [[ $# == 2 ]]; then
    binding="$(tmux display-message -p -t "$2" "$binding")"
  fi
  # Execute the configured binding on the private server, including its formats.
  tmux source-file - <<<"run-shell ${binding#*run-shell }"
}
assert-grid() {
  [[ "$(value "$A" pane_left)" == 0 && "$(value "$B" pane_left)" == 0 ]] || fail 'original stack is not on the left'
  [[ "$(value "$C" pane_left)" == "$(value "$D" pane_left)" && "$(value "$C" pane_left)" -gt 0 ]] || fail 'new stack is not on the right'
  [[ "$(value "$C" pane_top)" == 0 && "$(value "$A" pane_top)" == 0 ]] || fail 'top row is incorrect'
  [[ "$(value "$B" pane_top)" == "$(($(value "$A" pane_height) + 1))" ]] || fail 'stack has incorrect vertical geometry'
  [[ "$(value "$D" pane_top)" == "$(value "$B" pane_top)" && "$(value "$D" pane_top)" -gt 0 ]] || fail 'bottom row is incorrect'
}

tmux new-session -d -s test -x 200 -y 40 -c "$TEMP/project" 'exec sleep 120'
tmux source-file "$ROOT/config/.tmux.conf"
tmux set-option -g default-shell /bin/bash
tmux set-option -g default-command 'exec bash --noprofile --norc'
WINDOW="$(value test window_id)"
SESSION="$(value test session_id)"
A="$(value test pane_id)"
tmux set-option -t "$SESSION" @dev_workspace_path "$TEMP/project"
workspace agent-center-window "$WINDOW" "$SESSION"
assert-layout 1 2
workspace pane-remove "$A"
assert-layout 1 2
workspace pane-navigate "$A" left
assert-focus "$A"
key M-n
assert-focus "$A"
key M-p
assert-focus "$A"

key M-o
B="$(value "$WINDOW" pane_id)"
[[ "$B" != "$A" ]] || fail 'add did not focus a new pane'
assert-layout 2 2
[[ "$(value "$A" pane_left)" == "$(value "$B" pane_left)" && "$(value "$B" pane_top)" -gt 0 ]] || fail 'second pane is not below first'
[[ "$(value "$B" pane_current_path)" == "$TEMP/project" ]] || fail 'new shell did not inherit directory'
workspace pane-navigate "$B" up
assert-focus "$A"
workspace pane-navigate "$A" down
assert-focus "$B"
workspace pane-navigate "$B" right
assert-focus "$B"
key M-n
assert-focus "$A"
key M-p
assert-focus "$B"
key M-p
assert-focus "$A"
key M-n
assert-focus "$B"

workspace pane-add "$B"
C="$(value "$WINDOW" pane_id)"
assert-layout 3 0
[[ "$(value "$C" pane_left)" -gt 0 && "$(value "$C" pane_top)" == 0 && "$(value "$C" pane_height)" == 40 ]] || fail 'third pane is not full-height on the right'
[[ "$(value "$A" pane_left)" == 0 && "$(value "$B" pane_left)" == 0 && "$(value "$B" pane_top)" -gt 0 ]] || fail 'existing stack was not preserved on the left'
workspace pane-add "$C"
D="$(value "$WINDOW" pane_id)"
assert-layout 4 0
assert-grid
key M-o
key M-n
assert-focus "$A"
key M-n
assert-focus "$B"
key M-n
assert-focus "$C"
key M-p
assert-focus "$B"
key M-p
assert-focus "$A"
key M-p
assert-focus "$D"
assert-layout 4 0
assert-focus "$D"
workspace pane-navigate "$D" left
assert-focus "$B"
workspace pane-navigate "$B" up
assert-focus "$A"
workspace pane-navigate "$A" right
assert-focus "$C"

tmux resize-window -t "$WINDOW" -x 160 -y 32
for _ in {1..100}; do
  [[ "$(value "$A" pane_width)" == 79 && "$(value "$C" pane_width)" == 80 ]] && break
  sleep 0.02
done
assert-grid
[[ "$(value "$A" pane_width)" == 79 && "$(value "$C" pane_width)" == 80 ]] || fail 'grid did not resize'

# Native shell exit, not our remove command, must rebalance too.
tmux send-keys -t "$D" 'exit' Enter
assert-layout 3 0
for _ in {1..100}; do
  [[ "$(value "$C" pane_height)" == 32 ]] && break
  sleep 0.02
done
[[ "$(value "$C" pane_height)" == 32 ]] || fail 'shell exit did not rebalance'
tmux select-pane -t "$C"
key M-x
assert-layout 2 2
tmux resize-window -t "$WINDOW" -x 120
assert-layout 2 0
tmux resize-window -t "$WINDOW" -x 200
assert-layout 2 2

# Remove the original pane: management belongs to the window, not its first pane.
workspace pane-remove "$A"
assert-layout 1 2
assert-focus "$B"
workspace pane-add "$B"
C="$(value "$WINDOW" pane_id)"
workspace pane-add "$C"
D="$(value "$WINDOW" pane_id)"
assert-layout 3 0
workspace pane-remove "$B"
assert-layout 2 2
workspace pane-remove "$C"
assert-layout 1 2
key M-x
assert-layout 1 2

# Concurrent adds must respect the cap and never mistake new gutters for real panes.
workspace pane-add "$D" &
first=$!
workspace pane-add "$D" &
second=$!
workspace pane-add "$D" &
third=$!
workspace pane-add "$D" &
fourth=$!
wait "$first" "$second" "$third" "$fourth"
assert-layout 4 0

# Process preservation is checked separately from pane identity.
tmux new-session -d -s preserve -x 200 -y 40 'exec sleep 120'
original="$(value preserve pane_id)"
pid="$(value "$original" pane_pid)"
workspace pane-add "$original"
workspace pane-add "$original"
workspace pane-add "$original"
[[ "$(value "$original" pane_pid)" == "$pid" && "$(value "$original" pane_current_command)" == sleep ]] || fail 'layout replaced an existing process'
tmux kill-pane -t "$(value preserve pane_id)"
for _ in {1..100}; do
  remaining="$(tmux list-panes -t preserve -F '#{pane_id}' | sort -t '%' -k2,2n | tail -n1)"
  [[ "$(value "$remaining" pane_height)" == 40 ]] && break
  sleep 0.02
done
[[ "$(value "$original" pane_pid)" == "$pid" ]] || fail 'native removal replaced the original process'
[[ "$(value "$remaining" pane_height)" == 40 ]] || fail 'native kill did not rebalance the window'

tmux new-session -d -s last-exit -x 200 -y 40 'exec bash --noprofile --norc'
last="$(value last-exit pane_id)"
last_window="$(value last-exit window_id)"
tmux set-option -w -t "$last_window" @dev_workspace_panes 1
workspace pane-layout "$last_window"
tmux send-keys -t "$last" 'exit' Enter
for _ in {1..100}; do
  tmux has-session -t '=last-exit' 2>/dev/null || break
  sleep 0.02
done
if tmux has-session -t '=last-exit' 2>/dev/null; then
  fail 'last shell exit left gutter processes behind'
fi

# Exercise app-aware splitting without starting an authenticated AI session.
export PI_LAUNCHES="$TEMP/pi-launches"
cat >"$TEMP/bin/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\t%s\t%s\n' "$TMUX_PANE" "$PWD" "$#" >>"$PI_LAUNCHES"
exec -a pi sleep 120
EOF
cat >"$TEMP/bin/nvim" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec -a nvim sleep 120
EOF
chmod +x "$TEMP/bin/pi" "$TEMP/bin/nvim"
tmux set-environment -g PI_LAUNCHES "$PI_LAUNCHES"
mkdir -p "$TEMP/project/with spaces"
source_pane="$(tmux new-window -t "$SESSION" -n agent -c "$TEMP/project/with spaces" -P -F '#{pane_id}' "$TEMP/bin/pi" --continue)"
for _ in {1..100}; do
  [[ "$(value "$source_pane" pane_current_command)" == pi ]] && break
  sleep 0.02
done
[[ "$(value "$source_pane" pane_current_command)" == pi ]] || fail 'Pi fixture did not start'
key M-o "$source_pane"
new_pane="$(value "$(value "$source_pane" window_id)" pane_id)"
[[ "$new_pane" != "$source_pane" ]] || fail 'Pi split did not focus a new pane'
for _ in {1..100}; do
  [[ "$(value "$new_pane" pane_current_command)" == pi ]] && break
  sleep 0.02
done
if [[ "$(value "$new_pane" pane_current_command)" != pi ]]; then
  tmux capture-pane -p -t "$new_pane"
  fail 'Pi split did not start Pi'
fi
grep -Fxq "$(printf '%s\t%s\t0' "$new_pane" "$TEMP/project/with spaces")" "$PI_LAUNCHES" ||
  fail 'new Pi inherited arguments or lost the working directory'
[[ "$(value "$source_pane" pane_current_command)" == pi ]] || fail 'splitting interrupted the original Pi'
key M-o "$new_pane"
next_pane="$(value "$(value "$new_pane" window_id)" pane_id)"
[[ "$next_pane" != "$new_pane" ]] || fail 'a new Pi pane could not split again'
for _ in {1..100}; do
  [[ "$(value "$next_pane" pane_current_command)" == pi ]] && break
  sleep 0.02
done
[[ "$(value "$next_pane" pane_current_command)" == pi ]] || fail 'repeated Pi splitting opened a shell'

# A window name alone must never launch Pi after its process has exited.
shell_pane="$(tmux new-window -t "$SESSION" -n agent -P -F '#{pane_id}' 'exec sleep 120')"
key M-o "$shell_pane"
shell_split="$(value "$(value "$shell_pane" window_id)" pane_id)"
[[ "$shell_split" != "$shell_pane" && "$(value "$shell_split" pane_current_command)" != pi ]] ||
  fail 'an ordinary agent-window shell inherited Pi behavior'

editor="$(tmux new-window -t "$SESSION" -n scratch -P -F '#{pane_id}' "$TEMP/bin/nvim")"
for _ in {1..100}; do
  [[ "$(value "$editor" pane_current_command)" == nvim ]] && break
  sleep 0.02
done
[[ "$(value "$editor" pane_current_command)" == nvim ]] || fail 'Neovim fixture did not start'
layout="$(value "$editor" window_layout)"
key M-o "$editor"
[[ "$(value "$editor" window_layout)" == "$layout" ]] || fail 'Alt+O changed a Neovim pane'

manual="$(tmux new-window -t "$SESSION" -n dev -P -F '#{pane_id}' 'exec sleep 120')"
[[ "$(tmux list-panes -t "$manual" -F '#{pane_id}' | wc -l)" == 1 ]] ||
  fail 'dev window was automatically centered'
layout="$(value "$manual" window_layout)"
key M-o "$manual"
[[ "$(value "$manual" window_layout)" == "$layout" ]] || fail 'Alt+O split the dev window'
tmux split-window -d -h -t "$manual" 'exec sleep 120'
tmux set-option -w -t "$manual" @dev_workspace_panes 1
layout="$(value "$manual" window_layout)"
workspace pane-layout "$(value "$manual" window_id)"
[[ "$(value "$manual" window_layout)" == "$layout" ]] || fail 'automation rearranged a manual dev layout'

# The Pi extension preflights capacity, then requests an argv-preserving launch.
runner="$TEMP/bin/fork-runner"
cat >"$runner" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output="$1"
shift
printf '%s\0' "$PWD" "$@" >"$output"
exec sleep 120
EOF
chmod +x "$runner"
origin="$(tmux new-window -t "$SESSION" -n fork-test -P -F '#{pane_id}' 'exec sleep 120')"
before="$(value "$origin" window_layout)"
workspace pane-can-add "$origin"
[[ "$(value "$origin" window_layout)" == "$before" ]] || fail 'capacity check changed the layout'
output="$TEMP/fork argv"
fork_path="$TEMP/a fork's session.jsonl"
prompt="-review; touch '$TEMP/should-not-exist'"
opened="$(workspace pane-run "$origin" "$TEMP/project/with spaces" "$runner" "$output" --session "$fork_path" -- "$prompt")"
[[ "$opened" =~ ^%[0-9]+$ && "$(value "$(value "$origin" window_id)" pane_id)" == "$opened" ]] ||
  fail 'pane-run did not report and focus its new pane'
for _ in {1..100}; do
  [[ -f "$output" ]] && break
  sleep 0.02
done
printf '%s\0' "$TEMP/project/with spaces" --session "$fork_path" -- "$prompt" >"$TEMP/expected argv"
cmp "$output" "$TEMP/expected argv" || fail 'pane-run changed launch arguments'
[[ ! -e "$TEMP/should-not-exist" ]] || fail 'pane-run interpreted prompt text as shell code'
workspace pane-add "$origin"
workspace pane-can-add "$origin"
workspace pane-add "$origin"
code=0
workspace pane-run "$origin" "$TEMP/project" "$runner" "$TEMP/rejected" 2>"$TEMP/refusal" || code=$?
[[ "$code" == 2 && ! -e "$TEMP/rejected" ]] || fail 'pane-run bypassed a capacity change after preflight'
grep -q 'four-pane limit' "$TEMP/refusal" || fail 'capacity refusal did not explain the limit'
code=0
workspace pane-can-add "$manual" 2>/dev/null || code=$?
[[ "$code" == 2 ]] || fail 'capacity check allowed a manually managed dev window'
code=0
workspace pane-run %999999 "$TEMP/project" "$runner" "$TEMP/stale" 2>/dev/null || code=$?
[[ "$code" == 2 && ! -e "$TEMP/stale" ]] || fail 'pane-run launched from a stale source pane'

printf '[workspace-panes] OK\n'

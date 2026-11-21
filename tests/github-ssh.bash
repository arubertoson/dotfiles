#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
export HOME="$TEMP/home"
export PATH="$TEMP/bin:$PATH"
mkdir -p "$HOME/.ssh" "$TEMP/bin"
printf 'Existing SSH configuration\n' >"$HOME/.ssh/config"
cp "$HOME/.ssh/config" "$TEMP/config"

# GitHub returns status 1 even when authentication succeeds.
cat >"$TEMP/bin/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HOME/ssh-calls"
if [ "${SSH_TEST_FAIL:-0}" = 1 ]; then
  echo 'Permission denied (publickey).' >&2
  exit 255
fi
echo "Hi example! You've successfully authenticated, but GitHub does not provide shell access." >&2
exit 1
EOF
chmod +x "$TEMP/bin/ssh"
source "$ROOT/lib/ssh.sh"

setup-github-ssh '' home </dev/null
setup-github-ssh '' work </dev/null
grep -q 'git@github.com' "$HOME/ssh-calls"
grep -q 'git@github.work' "$HOME/ssh-calls"

export SSH_TEST_FAIL=1
if setup-github-ssh '' home </dev/null; then
  echo 'Failed SSH access must require interactive consent' >&2
  exit 1
fi
cmp "$TEMP/config" "$HOME/.ssh/config"
[ "$(find "$HOME/.ssh" -type f | wc -l)" -eq 1 ]
printf '[github-ssh] OK\n'

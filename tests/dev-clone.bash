#!/usr/bin/env bash
set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-dev-clone.XXXXXX")"
trap 'rm -rf -- "$TEMP"' EXIT

export HOME="$TEMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DEV_HOME="$TEMP/dev"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$TEMP/gitconfig"
mkdir -p "$HOME"
git init -q "$TEMP/source"
git -C "$TEMP/source" -c user.name=Test -c user.email=test@example.com commit -qm initial --allow-empty
# Rewrite a normal public remote to a local fixture so cloning stays offline.
git config --global url."file://$TEMP/source".insteadOf https://github.com/example/project.git

zsh -f -s -- "$ROOT" <<'EOF'
set -euo pipefail
fpath=("$1/config/zsh/functions" $fpath)
autoload -Uz dev-clone

for location in home library work; do
  args=()
  [[ "$location" == home ]] || args+=("--$location")
  dev-clone "${args[@]}" https://github.com/example/project.git
  dest="$XDG_DEV_HOME/$location/github.com/example/project"
  [[ "$(git -C "$dest" rev-parse HEAD)" == "$(git -C "$HOME/../source" rev-parse HEAD)" ]]
done

# Existing checkouts, including untracked work, must be left intact.
print keep > "$XDG_DEV_HOME/home/github.com/example/project/untracked"
dev-clone https://github.com/example/project.git
[[ "$(<"$XDG_DEV_HOME/home/github.com/example/project/untracked")" == keep ]]

dev-clone --help
for args in '' '--unknown' '--work' 'home remote' '--work --library remote'; do
  if dev-clone ${=args}; then
    print -u2 -- "accepted invalid arguments: $args"
    exit 1
  fi
done
EOF

printf '[dev-clone] passed\n'

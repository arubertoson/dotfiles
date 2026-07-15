#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf "\033[1;32m[UPDATE]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

cd "$REPO_DIR"

if [ -n "$(git status --porcelain)" ]; then
  error "Working directory not clean. Commit or stash changes first."
  exit 1
fi

log "Pulling latest changes..."
git pull --rebase

# shellcheck disable=SC1091
source "$REPO_DIR/lib/detect.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/lib/packages.sh"

log "Updating system packages..."
update-system-packages
install-system-packages
install-aur-packages

log "Reconciling mise..."
./bootstrap.d/20-mise
./bootstrap.d/35-dotfiles mise
./bootstrap.d/30-cli --upgrade
./bootstrap.d/32-completions

log "Applying dotfiles and scripts..."
./bootstrap.d/35-dotfiles
./bootstrap.d/40-scripts

log "Update complete! Run 'just status' to verify."

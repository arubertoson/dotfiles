#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf "\033[1;32m[UPDATE]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

cd "$REPO_DIR"

if git diff --quiet && git diff --staged --quiet; then
  log "Pulling latest changes..."
  git pull --rebase
else
  error "Working directory not clean. Commit or stash changes first."
  exit 1
fi

log "Updating scripts..."
./bootstrap.d/40-scripts

log "Updating mise configuration..."
./bootstrap.d/20-mise

log "Updating dotfiles..."
./bootstrap.d/35-dotfiles

log "Update complete! Run 'just status' to verify."

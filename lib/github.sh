#!/usr/bin/env bash

# Shared GitHub authentication checks for mise and explicit setup commands.

github-token-available() {
  command -v mise >/dev/null 2>&1 || return 1
  mise token github --raw >/dev/null 2>&1
}

github-auth-required() {
  if github-token-available; then
    return 0
  fi

  cat >&2 <<'EOF'
[github] GitHub credentials are unavailable to mise.
[github] Run: just github-auth
EOF
  return 1
}

github-auth-interactive() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "[github] GitHub CLI is not installed" >&2
    return 1
  fi

  if ! command -v mise >/dev/null 2>&1; then
    echo "[github] mise is not installed" >&2
    return 1
  fi

  if gh auth status --hostname github.com >/dev/null 2>&1; then
    gh auth setup-git --hostname github.com >/dev/null 2>&1 || true
    if github-token-available; then
      echo "[github] GitHub credentials are available to gh and mise"
      return 0
    fi
  fi

  if [ ! -t 0 ]; then
    echo "[github] Authentication is required but no interactive terminal is available" >&2
    echo "[github] Run interactively: just github-auth" >&2
    return 1
  fi

  echo "[github] Starting GitHub CLI authentication"
  gh auth login --hostname github.com --git-protocol ssh --web
  gh auth setup-git --hostname github.com >/dev/null 2>&1 || true

  if ! github-token-available; then
    echo "[github] Authentication succeeded, but mise cannot resolve the GitHub token" >&2
    return 1
  fi

  echo "[github] GitHub credentials are available to gh and mise"
}

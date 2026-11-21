#!/usr/bin/env bash

ensure-ssh-directory() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
}

ensure-github-key() {
  local email="$1"
  local key="$2"

  if [ -f "$key" ]; then
    if [ ! -f "$key.pub" ]; then
      ssh-keygen -y -f "$key" >"$key.pub"
    fi

    chmod 600 "$key"
    chmod 644 "$key.pub"
    return
  fi

  if [ -e "$key.pub" ]; then
    echo "[ssh] Public key exists without its private key: $key.pub" >&2
    return 1
  fi

  echo "[ssh] Generating $key with an empty passphrase"
  ssh-keygen -q -t ed25519 -a 100 -C "$email" -f "$key" -N ""
  chmod 600 "$key"
  chmod 644 "$key.pub"
}

configure-github-host() {
  local host="$1"
  local key="$2"
  local config="$HOME/.ssh/config"
  local tmp="$config.$$"
  local backup

  touch "$config"
  chmod 600 "$config"

  awk -v host="$host" '
    /^[[:space:]]*(Host|Match)[[:space:]]/ {
      drop = ($1 == "Host" && NF == 2 && $2 == host)
    }
    !drop { print }
  ' "$config" >"$tmp"

  cat >>"$tmp" <<EOF
Host $host
  HostName github.com
  User git
  IdentityFile $key
  IdentitiesOnly yes
EOF

  if cmp -s "$config" "$tmp"; then
    rm "$tmp"
    echo "[ssh] Host $host is configured correctly"
    return
  fi

  if [ -s "$config" ]; then
    backup="$config.backup.$(date +%Y%m%d%H%M%S)"
    cp -- "$config" "$backup"
    chmod 600 "$backup"
    echo "[ssh] Backed up SSH config to $backup"
  fi

  mv "$tmp" "$config"
  chmod 600 "$config"
  echo "[ssh] Configured Host $host"
}

register-github-key() {
  local key="$1"
  local title="$2"
  local public

  public="$(awk '{print $1 " " $2}' "$key.pub")"
  if gh ssh-key list 2>/dev/null | awk -F '\t' '{print $2}' | grep -qxF "$public"; then
    echo "[ssh] Public key is already registered with GitHub"
    return
  fi

  echo "[ssh] Registering public key with GitHub"
  if ! gh ssh-key add "$key.pub" --type authentication --title "$title"; then
    echo "[ssh] Could not register the key. The active account may need admin:public_key." >&2
    echo "[ssh] Run: gh auth refresh -h github.com -s admin:public_key" >&2
    return 1
  fi
}

verify-github-ssh() {
  local host="$1"
  local output

  output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T "git@$host" 2>&1 || true)"
  if [[ "$output" == *"successfully authenticated"* ]]; then
    echo "[ssh] GitHub SSH access verified through $host"
    return
  fi

  echo "[ssh] GitHub SSH verification failed through $host" >&2
  printf '%s\n' "$output" >&2
  return 1
}

setup-github-ssh() {
  local email="${1:-}"
  local profile="${2:-home}"
  local host="github.com"
  local key="$HOME/.ssh/id_ed25519_github"
  local public
  local choice
  local index
  local keys=()

  if [ "$profile" = work ]; then
    host="github.work"
    key="$HOME/.ssh/id_ed25519_github.work"
    email="${email:-${GITHUB_EMAIL_WORK:-}}"
  else
    email="${email:-${GITHUB_EMAIL_HOME:-}}"
  fi

  if verify-github-ssh "$host" >/dev/null 2>&1; then
    echo "[ssh] Reusing working GitHub SSH access through $host"
    return 0
  fi

  echo "[ssh] GitHub SSH access through $host is unavailable"
  if [ ! -t 0 ]; then
    echo "[ssh] Run interactively: ./bootstrap ssh '$email' '$profile'" >&2
    return 1
  fi

  for public in "$HOME"/.ssh/*.pub; do
    [ -f "$public" ] && [ -f "${public%.pub}" ] || continue
    keys+=("${public%.pub}")
  done

  echo "[ssh] Choose a key to configure and register with GitHub:"
  for index in "${!keys[@]}"; do
    printf '  %s) %s\n' "$((index + 1))" "${keys[$index]}"
  done
  printf '  0) Generate %s (empty passphrase)\n' "$key"
  read -r -p 'Key number (Enter to cancel): ' choice
  case "$choice" in
    0)
      if [ -e "$key" ] || [ -e "$key.pub" ]; then
        echo "[ssh] Key path already exists; select it above instead" >&2
        return 1
      fi
      ;;
    *)
      if [[ ! "$choice" =~ ^[1-9][0-9]{0,3}$ ]] || ((choice > ${#keys[@]})); then
        echo "[ssh] Cancelled; no SSH configuration changed" >&2
        return 1
      fi
      key="${keys[$((choice - 1))]}"
      ;;
  esac

  email="${email:-${USER:-user}@$(uname -n)}"
  ensure-ssh-directory
  ensure-github-key "$email" "$key"
  configure-github-host "$host" "$key"
  register-github-key "$key" "dotfiles-$(uname -n)-$profile"
  verify-github-ssh "$host"
}

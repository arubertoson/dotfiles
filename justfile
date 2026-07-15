# Dotfiles setup and lifecycle commands

default:
    @just --list

bootstrap:
    @./bootstrap

# Reconcile managed configuration without packages, authentication, or network access.
apply:
    @./bootstrap.d/35-dotfiles
    @./bootstrap.d/40-scripts
    @./bootstrap.d/32-completions

# Backwards-compatible alias.
bootstrap-config: apply

# Verify repeatable reconciliation in an isolated temporary home.
smoke:
    @./tests/apply-smoke.bash

detect:
    @bash -lc 'source ./lib/detect.sh; _dot_detect_log'

packages:
    @bash -lc 'source ./lib/detect.sh; source ./lib/packages.sh; install-system-packages; install-aur-packages'
    @./bootstrap.d/32-completions

github-auth:
    @./bootstrap.d/20-mise
    @./bootstrap.d/35-dotfiles mise
    @./bootstrap.d/25-github-auth

mise:
    @./bootstrap.d/20-mise
    @./bootstrap.d/35-dotfiles mise
    @./bootstrap.d/30-cli
    @./bootstrap.d/32-completions

completions:
    @./bootstrap.d/32-completions

dotfiles component="":
    @./bootstrap.d/35-dotfiles "{{component}}"

adopt-dotfiles:
    @DOTFILES_REPLACE_DIRS=1 ./bootstrap.d/35-dotfiles

scripts:
    @./bootstrap.d/40-scripts

update component="":
    @if [ "{{component}}" = "packages" ]; then \
        bash -lc 'source ./lib/detect.sh; source ./lib/packages.sh; update-system-packages; install-system-packages; install-aur-packages' && ./bootstrap.d/32-completions; \
    elif [ "{{component}}" = "scripts" ]; then \
        ./bootstrap.d/40-scripts; \
    elif [ "{{component}}" = "dotfiles" ]; then \
        ./bootstrap.d/35-dotfiles; \
    elif [ "{{component}}" = "mise" ]; then \
        ./bootstrap.d/20-mise && ./bootstrap.d/35-dotfiles mise && ./bootstrap.d/30-cli --upgrade && ./bootstrap.d/32-completions; \
    elif [ "{{component}}" = "" ]; then \
        ./update.sh; \
    else \
        echo "Unknown component: {{component}}"; \
        echo "Available: packages, scripts, dotfiles, mise"; \
        exit 1; \
    fi

# Configure and register a fixed-empty-passphrase GitHub SSH key.
ssh email="" profile="":
    @./bootstrap.d/55-ssh "{{email}}" "{{profile}}"

# Configure personal GitHub SSH, clone the Neovim config, and link it.
nvim:
    @./bootstrap.d/50-nvim

status:
    @echo "=== Dotfiles Status ==="
    @bash -lc 'source ./lib/detect.sh; _dot_detect_log'
    @echo "Zsh: $(command -v zsh || echo 'NOT FOUND')"
    @echo "Mise: $(mise --version 2>/dev/null || echo 'NOT FOUND')"
    @echo "Scripts dir: ${XDG_BIN_HOME:-$HOME/.local/bin}"
    @ls -la ${XDG_BIN_HOME:-$HOME/.local/bin}/ | grep -E '\->' | head -5 || echo "No scripts linked"
    @echo "=== Managed config links ==="
    @bash -lc 'shopt -s dotglob nullglob; for source in dotfiles/*; do name="$(basename "$source")"; target="${XDG_CONFIG_HOME:-$HOME/.config}/$name"; if [ "$name" = ".tmux.conf" ]; then target="$HOME/$name"; fi; if [ -L "$target" ]; then printf "%-14s -> %s\n" "$name" "$(readlink "$target")"; continue; fi; if [ -e "$target" ]; then printf "%-14s NOT LINKED (%s)\n" "$name" "$(stat -c %F "$target")"; continue; fi; printf "%-14s missing\n" "$name"; done'
    @echo "=== Setup operations ==="
    @ls -la bootstrap.d/ | grep -E '^[d-].*[0-9][0-9]-' | awk '{print $9}'

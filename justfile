# Justfile for dotfiles/zsh configuration management

default:
    @just --list

bootstrap:
    @./bootstrap

# Link configs/scripts without running package or mise installs.
bootstrap-config:
    @DOT_SKIP_PACKAGES=1 ./bootstrap.d/35-dotfiles
    @./bootstrap.d/40-scripts

detect:
    @bash -lc 'source ./lib/detect.sh; _dot_detect_log'

packages:
    @bash -lc 'source ./lib/detect.sh; source ./lib/packages.sh; install-system-packages; install-aur-packages'

mise:
    @./bootstrap.d/20-mise
    @./bootstrap.d/30-cli

dotfiles:
    @./bootstrap.d/35-dotfiles

scripts:
    @./bootstrap.d/40-scripts

update component="":
    @if [ "{{component}}" = "packages" ]; then \
        just packages; \
    elif [ "{{component}}" = "scripts" ]; then \
        ./bootstrap.d/40-scripts; \
    elif [ "{{component}}" = "dotfiles" ]; then \
        ./bootstrap.d/35-dotfiles; \
    elif [ "{{component}}" = "mise" ]; then \
        ./bootstrap.d/20-mise && ./bootstrap.d/30-cli; \
    elif [ "{{component}}" = "ssh" ]; then \
        ./bootstrap.d/55-ssh; \
    elif [ "{{component}}" = "ssh-work" ]; then \
        ./bootstrap.d/55-ssh "" work; \
    elif [ "{{component}}" = "" ]; then \
        ./update.sh; \
    else \
        echo "Unknown component: {{component}}"; \
        echo "Available: packages, scripts, dotfiles, mise, ssh, ssh-work"; \
        exit 1; \
    fi

# SSH setup - prompts for email if not provided
# Usage: just ssh [email] [profile]
ssh email="" profile="":
    @./bootstrap.d/55-ssh "{{email}}" "{{profile}}"

status:
    @echo "=== Dotfiles Status ==="
    @bash -lc 'source ./lib/detect.sh; _dot_detect_log'
    @echo "Zsh: $(command -v zsh || echo 'NOT FOUND')"
    @echo "Mise: $(mise --version 2>/dev/null || echo 'NOT FOUND')"
    @echo "Scripts dir: ${XDG_BIN_HOME:-$HOME/.local/bin}"
    @ls -la ${XDG_BIN_HOME:-$HOME/.local/bin}/ | grep -E '\->' | head -5 || echo "No scripts linked"
    @echo "=== Bootstrap stages ==="
    @ls -la bootstrap.d/ | grep -E '^[d-].*[0-9][0-9]-' | awk '{print $9}'

# Create isolated test environment in /tmp for development testing
test-env:
    @echo "Setting up test environment..."
    @mkdir -p /tmp/zsh-test
    @cp -r . /tmp/zsh-test/
    @cd /tmp/zsh-test && export HOME=/tmp/zsh-test-home && mkdir -p $HOME && DOT_SKIP_PACKAGES=1 ./bootstrap
    @echo "Test environment ready in /tmp/zsh-test"

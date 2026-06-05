# Justfile for zsh configuration management

default:
    @just --list

bootstrap:
    @./bootstrap

update component="":
    @if [ "{{component}}" = "scripts" ]; then \
        ./bootstrap.d/40-scripts; \
    elif [ "{{component}}" = "dotfiles" ]; then \
        ./bootstrap.d/35-dotfiles; \
    elif [ "{{component}}" = "mise" ]; then \
        ./bootstrap.d/20-mise; \
    elif [ "{{component}}" = "ssh" ]; then \
        ./bootstrap.d/55-ssh; \
    elif [ "{{component}}" = "ssh-work" ]; then \
        ./bootstrap.d/55-ssh "" work; \
    elif [ "{{component}}" = "" ]; then \
        ./update.sh; \
    else \
        echo "Unknown component: {{component}}"; \
        echo "Available: scripts, dotfiles, mise, ssh, ssh-work"; \
        exit 1; \
    fi

# SSH setup - prompts for email if not provided
# Usage: just setup-ssh [email] [profile]
# Examples:
#   just setup-ssh                    # Personal account, prompts for email
#   just setup-ssh user@example.com   # Personal account with email
#   just setup-ssh user@work.com work # Work account
ssh email="" profile="":
    @./bootstrap.d/55-ssh "{{email}}" "{{profile}}"

status:
    @echo "=== Zsh Configuration Status ==="
    @echo "Zsh: $(command -v zsh || echo 'NOT FOUND')"
    @echo "Mise: $(mise --version 2>/dev/null || echo 'NOT FOUND')"
    @echo "Scripts dir: $XDG_BIN_HOME"
    @ls -la $XDG_BIN_HOME/ | grep -E '\->' | head -5 || echo "No scripts linked"
    @echo "=== Bootstrap stages ==="
    @ls -la bootstrap.d/ | grep -E '^[d-].*[0-9][0-9]-' | awk '{print $9}'

# Create isolated test environment in /tmp for development testing
test-env:
    @echo "Setting up test environment..."
    @mkdir -p /tmp/zsh-test
    @cp -r . /tmp/zsh-test/
    @cd /tmp/zsh-test && export HOME=/tmp/zsh-test-home && mkdir -p $HOME && ./bootstrap
    @echo "Test environment ready in /tmp/zsh-test"

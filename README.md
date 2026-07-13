# Dotfiles / Zsh Configuration

To set up this environment:

1. Clone this repository anywhere temporary is fine
2. Run `./bootstrap` to set up the environment
3. Optionally copy `.env.example` to `~/.env` after `gh auth login` and fill in local values

`./bootstrap` is the zero-dependency entrypoint. On first run, it moves this
checkout into the canonical dev location:

```text
~/dev/home/github.com/arubertoson/zsh
```

Override the location with `DOTFILES_REPO_DIR`, or disable the move with
`DOTFILES_ADOPT_REPO=0`.

`just` is installed/managed by mise during bootstrap and is only expected to be
available after the first run.

## Project Architecture

This project is structured to manage a shell/dev/desktop environment in a modular and organized way.

*   **`bootstrap.d/`**: Contains scripts for the initial setup and bootstrapping of the environment. Files are executed in numerical order (e.g., `00-zsh`, `10-dev`), ensuring dependencies are met.
*   **`rc.d/`**: Holds the core Zsh configuration files that are loaded when the shell starts. Similar to `bootstrap.d/`, files are sourced in numerical order (e.g., `01-hist.zsh`, `02-dirs.zsh`).
*   **`functions/`**: This directory is for custom, reusable Zsh functions that can be autoloaded by the shell.
*   **`scripts/`**: Contains standalone, executable shell scripts that provide utility functions or automate tasks.
*   **`lib/`**: Shared bootstrap helpers, including platform/profile detection.
*   **`packages/`**: Extensionless package manifests for supported platforms.

## Profiles

Bootstrap detects the current profile automatically and can be overridden:

```sh
DOT_PROFILE=arch-desktop ./bootstrap
DOT_PROFILE=wsl-ubuntu ./bootstrap
```

Supported profiles:

* `arch-desktop` - Arch-based native desktop with niri/Ghostty/Noctalia/rofi.
* `arch` - Arch-based terminal/base setup without desktop dotfiles.
* `wsl-ubuntu` - Ubuntu under WSL2, tmux-first workflow.

Inspect detection with:

```sh
bash -lc 'source ./lib/detect.sh; _dot_detect_log'
# after bootstrap: just detect
```

## Managed Desktop Dotfiles

The repo also carries the local desktop/session pieces used by the workspace flow:

* `dotfiles/niri/` - niri config and `Alt+S`/`Alt+W`/`Alt+A`/`Alt+1..3` bindings.
* `dotfiles/ghostty/` - Ghostty terminal config.
* `dotfiles/rofi/` - terminal-like rofi theme for pickers.
* `dotfiles/noctalia/` - Noctalia settings/colors/plugins.
* `dotfiles/environment.d/` - user session PATH, including `~/.local/bin`.

`./bootstrap` links these into `~/.config`. If an existing config directory is
already present, it is skipped by default. To adopt a machine into the repo-managed
config, run:

```sh
DOTFILES_REPLACE_DIRS=1 ./bootstrap
# or, after bootstrap is already installed:
just adopt-dotfiles
```

Existing directories are moved to `*.backup.<timestamp>` before linking. Use
`just status` to verify managed config paths are symlinks.

## Dev Workspaces

`dev-workspace` is the backend-neutral project/session launcher.

* Local niri/Ghostty flow: `dev-workspace project`, `dev-workspace sessions`,
  `dev-workspace windows`, `dev-workspace slot dev|term|agent`,
  `dev-workspace new dev|term|agent`.
* tmux flow: set `DEV_WORKSPACE_BACKEND=tmux` or run inside tmux; the command delegates to `tmux-workspace`.
* Projects are discovered under `$XDG_DEV_HOME`/`~/dev` by looking for Git (`.git`) and Jujutsu (`.jj`) repositories.
* In Ghostty, auto-tmux is skipped unless `AUTO_TMUX=1` is explicitly set, preserving direct terminal protocols for local workspaces.

Recommended niri bindings:

```kdl
Alt+S       { spawn "dev-workspace" "project"; }
Alt+W       { spawn "dev-workspace" "sessions"; }
Alt+Shift+W { spawn "dev-workspace" "windows"; }
Alt+A       { focus-workspace-previous; }
Alt+1       { spawn "dev-workspace" "slot" "dev"; }
Alt+2       { spawn "dev-workspace" "slot" "term"; }
Alt+3       { spawn "dev-workspace" "slot" "agent"; }
Alt+Shift+1 { spawn "dev-workspace" "new" "dev"; }
Alt+Shift+2 { spawn "dev-workspace" "new" "term"; }
Alt+Shift+3 { spawn "dev-workspace" "new" "agent"; }
```

## Available Commands

`./bootstrap` is the canonical first-run command. After bootstrap, this project
uses `just` for task automation:

*   `just default`: Lists all available `just` commands.
*   `just bootstrap`: Re-runs the main bootstrapping script (`./bootstrap`).
*   `just detect`: Shows detected platform/profile values.
*   `just packages`: Installs system packages for the detected profile.
*   `just mise`: Installs/links mise and installs mise-managed tools.
*   `just dotfiles`: Links profile-appropriate dotfiles.
*   `just adopt-dotfiles`: Backs up existing config directories and replaces them with repo symlinks.
*   `just scripts`: Links scripts to `~/.local/bin`.
*   `just bootstrap-config`: Links dotfiles/scripts without installing packages or mise tools.
*   `just update [component]`: Updates specific components.
    *   `component` can be `packages`, `scripts`, `dotfiles`, `mise`, `ssh`, or `ssh-work`.
    *   If no component is specified, it runs the main update script (`./update.sh`).
*   `just ssh [email] [profile]`: Sets up SSH keys and configuration.
    *   `email`: Optional email for the SSH key.
    *   `profile`: Optional profile (e.g., `work`).
*   `just status`: Displays the current status of the Zsh configuration, including Zsh/Mise versions, linked scripts, and managed config symlinks.
*   `just test-env`: Sets up an isolated test environment in `/tmp` for development and testing purposes.

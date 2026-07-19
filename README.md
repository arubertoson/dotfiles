# Dotfiles

Profile-aware setup for a Zsh development environment, terminal workflows, and
an optional niri desktop.

## First setup

```sh
git clone https://github.com/arubertoson/dotfiles.git
cd dotfiles
./bootstrap
```

Bootstrap is the zero-dependency entrypoint. On its first run it moves the
checkout to the canonical development path:

```text
~/dev/home/github.com/arubertoson/dotfiles
```

Set `DOTFILES_REPO_DIR` to choose another path, or set
`DOTFILES_ADOPT_REPO=0` to keep the checkout where it is.

Bootstrap:

1. Installs missing packages without performing a full system update.
2. Installs mise and links its configuration.
3. Authenticates GitHub interactively when required.
4. Installs mise-managed tools.
5. Applies managed dotfiles and scripts.
6. Sets Zsh as the login shell.

It can be run repeatedly. SSH keys and the separate Neovim configuration are
explicit setup operations and do not run during bootstrap. `./bootstrap help`
lists every lifecycle command; `just` provides short aliases for the same commands.

Copy `.env.example` to `~/.env` only when machine-local values are needed,
then run `chmod 600 ~/.env`. Interactive Zsh shells export these values to the
commands they launch. GitHub credentials remain in the GitHub CLI credential
store, not this file.

## Architecture

- **`bootstrap`** is the setup and lifecycle command interface.
- **`config/`** contains application configuration linked into `~/.config`
  and other documented targets.
- **`config/zsh/`** contains `.zshenv`, `.zshrc`, ordered `rc.d/` modules, and
  autoloadable functions.
- **`scripts/`** contains standalone commands linked into `~/.local/bin`.
- **`lib/`** contains reusable detection, package, configuration, GitHub, and SSH logic.
- **`packages/`** contains profile-specific system package manifests.
- **`justfile`** contains convenience aliases that delegate to `bootstrap`.

Zsh is managed as:

```text
~/.zshenv     -> <repo>/config/zsh/.zshenv
~/.config/zsh -> <repo>/config/zsh
```

## Profiles

Bootstrap detects its profile automatically. Override it when necessary:

```sh
DOT_PROFILE=arch-desktop ./bootstrap
DOT_PROFILE=wsl-ubuntu ./bootstrap
```

Supported profiles:

- `arch-desktop`: Arch-based niri desktop with Ghostty, Noctalia, and rofi.
- `arch`: Arch-based terminal setup without desktop dotfiles.
- `wsl-ubuntu`: Ubuntu under WSL2 with a tmux-first workflow.

Full provisioning fails on unknown profiles. Profile-neutral dotfiles can still
be applied directly. Inspect detection with:

```sh
just detect
```

## Lifecycle commands

### Apply configuration

```sh
just apply
```

This is the fast, noninteractive reconciliation command. It links dotfiles and
scripts without packages, authentication, `sudo`, Git operations, or network
access. Missing managed links are restored. Existing unmanaged files and
directories are left untouched.

To back up existing paths and replace them with managed links:

```sh
just adopt-dotfiles
```

Backups use the suffix `.backup.<timestamp>`.

A single dotfile component can be applied with, for example:

```sh
just dotfiles zsh
just dotfiles mise
```

Verify reconciliation against an isolated temporary home with:

```sh
just smoke
```

The smoke test checks repeatability, drift repair, unmanaged-path preservation,
scoped stale-link cleanup, and the absence of privileged or network commands.

### Install declared packages

```sh
just packages
```

This installs missing packages from the detected profile manifests. It does not
remove undeclared packages or intentionally perform a full system update.

### Reconcile mise tools

```sh
just mise
```

This installs mise, applies its global configuration, requires existing GitHub
credentials, runs `mise install`, and refreshes generated Zsh completions. If
credentials are missing, run:

```sh
just github-auth
```

Generated completions for available supported commands can also be refreshed
without installing or updating anything:

```sh
just completions
```

### Install repository hooks

```sh
just hooks
```

Bootstrap installs the repository-local mise tools and activates the tracked
pre-commit hook automatically. The hook checks the staged snapshot with
`shfmt`, `bash -n`, and `zsh -n`; it rejects invalid commits without modifying
the index. Run `just format` before committing when formatting fails.

### Update the machine

```sh
just update
```

A full update requires a clean repository, pulls with rebase, updates system
packages, reconciles package manifests, upgrades floating mise declarations,
installs missing pinned tools, and applies dotfiles and scripts.

Component updates remain available:

```sh
just update packages
just update mise
just update dotfiles
just update scripts
```

### Configure GitHub SSH

```sh
just ssh [email] [home|work]
```

This creates an Ed25519 key with an empty passphrase, configures its GitHub host,
registers the public key through the authenticated GitHub CLI account, and
verifies SSH access. It backs up an existing changed SSH config before replacing
the selected GitHub host block.

### Configure Neovim

```sh
just nvim
```

This ensures personal GitHub SSH access, clones
`git@github.com:arubertoson/nvim.git` into the canonical development tree when
absent, and links `~/.config/nvim`. An existing checkout is never pulled, reset,
or otherwise modified.

## Managed desktop configuration

The `arch-desktop` profile applies:

- `config/niri/`
- `config/ghostty/`
- `config/rofi/`
- `config/noctalia/`
- `config/environment.d/`

Other shared configuration, including Git, mise, tmux, and Zsh, applies to all
supported profiles.

## Development workspaces

`dev-workspace` is the backend-neutral project and session launcher.

- On niri it manages named project workspaces and Ghostty window slots.
- In tmux, or with `DEV_WORKSPACE_BACKEND=tmux`, it manages tmux sessions and
  canonical `dev`, `term`, `agent`, and `serv` windows directly.
- Projects are discovered below `$XDG_DEV_HOME`/`~/dev` from Git and Jujutsu
  repositories.
- Ghostty skips automatic tmux unless `AUTO_TMUX=1` is explicitly set.

Common commands:

```sh
dev-workspace project
dev-workspace sessions
dev-workspace windows
dev-workspace slot dev
dev-workspace slot term
dev-workspace slot agent
```

Interactive Zsh also provides focused project setup helpers:

```sh
dev-clone [location] <remote>
dev-new [location] <name> [--git|--no-git]
dev-scratch <name> [--git|--no-git]
```

Run `just status` to inspect profile detection, tool availability, and managed
configuration links.

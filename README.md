# 🏠 here be dotfiles

> **Disclaimer:** These are my personal dotfiles, built for my machines and
> workflows. They support an Arch desktop and Ubuntu under WSL, but they’re
> opinionated and probably won’t fit your setup unchanged. Steal what’s useful;
> only blame me for what you keep.

## What this manages

A profile-aware Zsh and terminal environment, with an optional niri desktop.
Bootstrap handles machine setup and configuration; a separate fast apply command
reconciles managed links without installing packages or touching the network.

## How it’s organized

- `bootstrap` is the setup and lifecycle command interface.
- `config/` contains application configuration linked into `~/.config` and
  other documented targets.
- `config/zsh/` contains `.zshenv`, `.zshrc`, ordered `rc.d/` modules, and
  autoloadable functions.
- `scripts/` contains standalone commands linked into `~/.local/bin`.
- `lib/` contains reusable detection, package, configuration, GitHub, and SSH
  logic.
- `packages/` contains profile-specific system package manifests.
- `justfile` provides short aliases for `bootstrap` commands.

Zsh is managed as:

```text
~/.zshenv     -> <repo>/config/zsh/.zshenv
~/.config/zsh -> <repo>/config/zsh
```

## Profiles

Bootstrap detects the machine profile automatically. Override detection when
needed:

```sh
DOT_PROFILE=arch-desktop ./bootstrap
DOT_PROFILE=wsl-ubuntu ./bootstrap
```

- `arch-desktop`: Arch-based niri desktop with Ghostty, Noctalia, and rofi.
- `arch`: Arch-based terminal setup without desktop dotfiles.
- `wsl-ubuntu`: Ubuntu under WSL2 with a tmux-first workflow.

Full provisioning fails on unknown profiles, but profile-neutral dotfiles can
still be applied directly. Inspect detection with `just detect`.

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

Bootstrap installs missing packages without a full system update, installs
mise and its tools, applies managed dotfiles and scripts, and sets Zsh as the
login shell. It can be run repeatedly. SSH keys and the separate Neovim
configuration are explicit setup operations, not part of bootstrap. Run
`./bootstrap help` to see the available commands; `just` provides aliases.

Copy `.env.example` to `~/.env` only when machine-local values are needed, then
run `chmod 600 ~/.env`. Interactive Zsh shells export these values to commands
they launch.

## Development

Bootstrap installs the repository-local mise tools and activates the tracked
pre-commit hook. The hook checks staged changes with `shfmt`, `bash -n`, and
`zsh -n`; it rejects invalid commits without modifying the index. Run
`just format` before committing when formatting fails.

It works on my machines. If it works on yours, that’s between you and your machines.

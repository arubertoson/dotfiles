# Packages

Extensionless files in this directory are plain-text package manifests.

Comments and blank lines are ignored. Normal packages are installed with the
profile package manager (`paru`/`pacman` on Arch, `apt` on Ubuntu). AUR-specific
files are only used when `paru` is available.

Profiles currently compose manifests like this:

- `arch` -> `arch` + `arch-aur`
- `arch-desktop` -> `arch` + `arch-desktop` + `arch-aur` + `arch-desktop-aur`
- `wsl-ubuntu` -> `ubuntu` + `wsl-ubuntu`

Keep OS/session packages here. Prefer mise for user-space developer tools and
bleeding-edge/custom versions such as Neovim nightly.

Command ownership follows these boundaries:

- The system package manager owns bootstrap, OS, shell, and session tools such
  as GitHub CLI, Zsh, and jq.
- Mise owns language runtimes and versioned user-space development tools,
  including tmux where configuration requires a newer release.
- `scripts/` owns custom commands and intentional on-demand package launchers.
- Project-specific tools belong in each project's mise configuration instead of
  the global fallback configuration.

`just packages` installs missing declarations without intentionally upgrading
the full system. `just update` performs the platform update first and then
reconciles these manifests. Removing a declaration does not uninstall a package.

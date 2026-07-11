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

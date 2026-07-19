# Packages

Extensionless files in this directory are plain-text package manifests.

Comments and blank lines are ignored. Normal packages are installed with the
profile package manager (`paru`/`pacman` on Arch, `apt` on Ubuntu). AUR-specific
files are only used when `paru` is available.

Profiles currently compose manifests like this:

- `arch` -> `arch` + `arch-aur`
- `arch-desktop` -> `arch` + `arch-desktop` + `arch-aur` + `arch-desktop-aur`
- `wsl-ubuntu` -> `ubuntu` + `wsl-ubuntu`

The manifests intentionally start with only each platform's standard build
toolchain: `base-devel` on Arch and `build-essential` on Ubuntu. Add OS/session
packages only when the managed configuration requires them. Keep empty profile
manifests as extension-point contracts.

Prefer mise for language runtimes and versioned user-space developer tools.
Custom commands belong in `scripts/`, and project-specific tools belong in each
project's mise configuration instead of the global fallback configuration.

`just packages` installs missing declarations without intentionally upgrading
the full system. `just update` performs the platform update first and then
reconciles these manifests. Removing a declaration does not uninstall a package.

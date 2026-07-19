# Convenience aliases; ./bootstrap is the command interface and source of truth.

default:
  @just --list

# Format Bash and the Zsh files supported by shfmt's current Zsh parser.
format:
  @shfmt -w -i 2 -ci -ln bash .githooks/pre-commit bootstrap lib/*.sh scripts/dev-workspace scripts/dev-workspace.d/*.bash tests/*.bash
  @find config/zsh -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zshenv' \) ! -path 'config/zsh/.zshrc' ! -path 'config/zsh/rc.d/06-plugins.zsh' -print0 | xargs -0 shfmt -w -i 2 -ci -ln zsh

# Fail when committed shell files are not formatted.
format-check:
  @shfmt -d -i 2 -ci -ln bash .githooks/pre-commit bootstrap lib/*.sh scripts/dev-workspace scripts/dev-workspace.d/*.bash tests/*.bash
  @find config/zsh -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zshenv' \) ! -path 'config/zsh/.zshrc' ! -path 'config/zsh/rc.d/06-plugins.zsh' -print0 | xargs -0 shfmt -d -i 2 -ci -ln zsh

# Parse every shell file with its native shell.
shell-syntax:
  @bash -n .githooks/pre-commit bootstrap lib/*.sh scripts/dev-workspace scripts/dev-workspace.d/*.bash tests/*.bash
  @find config/zsh -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zshenv' \) -print0 | xargs -0 -n 1 zsh -n

# Run every check expected to pass before committing.
check: format-check shell-syntax smoke

# Install and activate this repository's pre-commit hook.
hooks:
  @./bootstrap hooks

bootstrap:
  @./bootstrap

apply:
  @./bootstrap apply

packages:
  @./bootstrap packages

github-auth:
  @./bootstrap github-auth

mise:
  @./bootstrap mise

completions:
  @./bootstrap completions

dotfiles component="":
  @./bootstrap dotfiles "{{component}}"

adopt-dotfiles:
  @./bootstrap adopt-dotfiles

scripts:
  @./bootstrap scripts

update component="":
  @./bootstrap update "{{component}}"

ssh email="" profile="":
  @./bootstrap ssh "{{email}}" "{{profile}}"

nvim:
  @./bootstrap nvim

status:
  @./bootstrap status

smoke:
  @./tests/apply-smoke.bash

detect:
  @./bootstrap detect

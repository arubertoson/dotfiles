# Convenience aliases; ./bootstrap is the command interface and source of truth.

default:
  @just --list

bootstrap:
  @./bootstrap

apply:
  @./bootstrap apply

bootstrap-config: apply

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

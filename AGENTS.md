# Agent Guidelines for Zsh Configuration

## Code Style Guidelines

### Shell Scripts (Bash/Zsh)
- Use `#!/usr/bin/env bash` or `#!/bin/zsh` shebang
- Enable strict mode: `set -euo pipefail`
- Use UPPER_CASE for global constants and configuration variables
- Use lowercase for local variables and functions
- Functions: kebab-case naming (e.g., `dev-clone`, `norm_repo`)
- Error handling: Use `exit 1` for failures, provide usage functions
- Quotes: Double-quote variables and command substitutions
- Comments: Explain the "why" not the "what" - avoid comments that just restate what the code is doing
- Structure: Use properly named functions instead of comments to describe code sections

### Zsh Configuration
- Use anonymous functions `()` for scoping when loading configs
- Glob patterns: Use extended globbing with `(n)` for numerical sorting
- Variable expansion: Use `${VAR:-default}` for defaults, `${VAR#prefix}` for trimming
- Path handling: Use `XDG_*` environment variables when available
- Plugin loading: Source files in numerical order with `<->-*.zsh(n)`

### General

- Try to keep things in one function unless composable or reusable
- DO NOT do unnecessary destructuring of variables
- DO NOT use `else` statements unless necessary
- AVOID `else` statements
- PREFER single word variable names where possible
- Indentation: 2 spaces or tabs consistently (follow existing file style)
- Line length: Keep under 100 characters when possible
- Imports: Source files with `source $file` (zsh) or explicit paths
- No trailing whitespace
- Use `local` in functions to avoid global pollution

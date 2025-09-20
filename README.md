# Zsh Configuration

To set up this zsh configuration:

1. Clone this repository
2. Run `just bootstrap` to set up the environment
  - If this is the first run, you'll have to run using bash shell `./bootstrap`
3. Create a symbolic link of `.zshenv` to your home directory

## Project Architecture

This project is structured to manage a Zsh environment in a modular and organized way.

*   **`bootstrap.d/`**: Contains scripts for the initial setup and bootstrapping of the environment. Files are executed in numerical order (e.g., `00-zsh`, `10-dev`), ensuring dependencies are met.
*   **`rc.d/`**: Holds the core Zsh configuration files that are loaded when the shell starts. Similar to `bootstrap.d/`, files are sourced in numerical order (e.g., `01-hist.zsh`, `02-dirs.zsh`).
*   **`functions/`**: This directory is for custom, reusable Zsh functions that can be autoloaded by the shell.
*   **`scripts/`**: Contains standalone, executable shell scripts that provide utility functions or automate tasks.

## Available Commands

This project uses `just` for task automation. Here are the available commands:

*   `just default`: Lists all available `just` commands.
*   `just bootstrap`: Runs the main bootstrapping script (`./bootstrap`) to set up the Zsh environment.
*   `just update [component]`: Updates specific components of the Zsh configuration.
    *   `component` can be `scripts`, `dotfiles`, `mise`, `ssh`, or `ssh-work`.
    *   If no component is specified, it runs the main update script (`./update.sh`).
*   `just ssh [email] [profile]`: Sets up SSH keys and configuration.
    *   `email`: Optional email for the SSH key.
    *   `profile`: Optional profile (e.g., `work`).
*   `just status`: Displays the current status of the Zsh configuration, including Zsh and Mise versions, and linked scripts.
*   `just test-env`: Sets up an isolated test environment in `/tmp` for development and testing purposes.

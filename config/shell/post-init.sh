#!/usr/bin/env bash

# These depends on anything being loaded before initializing themselves

# Starship prompt (shell-aware)
command -v starship >/dev/null && eval "$(starship init "$SHELL_TYPE")"

# zoxide init (shell-aware, only if installed)
command -v zoxide >/dev/null && eval "$(zoxide init "$SHELL_TYPE")"

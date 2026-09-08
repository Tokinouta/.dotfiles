#!/usr/bin/env bash

# These depends on anything being loaded before initializing themselves

# Starship prompt (shell-aware)
command -v starship >/dev/null && eval "$(starship init "$SHELL_TYPE")"

# zoxide init (shell-aware, only if installed)
command -v zoxide >/dev/null && eval "$(zoxide init "$SHELL_TYPE")"

# zsh-only ZLE plugins — both projects' docs require sourcing at the end of the rc.
# On zsh < 5.9 syntax-highlighting wraps every ZLE widget at source time, so order
# matters; on 5.9+ it registers zle-line-pre-redraw hooks instead.
# Source the first existing install location (apt, Homebrew, or git clone).
if [ "$SHELL_TYPE" = "zsh" ]; then
  for p in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
           /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
           /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
           "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
    [ -f "$p" ] && source "$p" && break
  done
  for p in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
           /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
           /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
           "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    [ -f "$p" ] && source "$p" && break
  done
  unset p
fi

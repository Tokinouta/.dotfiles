# Dotfiles main entry point for bash/zsh
DOTFILES="${HOME}/.dotfiles/config/bash"

[ -f "$DOTFILES/config.sh" ]    && source "$DOTFILES/config.sh"
[ -f "$DOTFILES/env.sh" ]       && source "$DOTFILES/env.sh"
[ -f "$DOTFILES/aliases.sh" ]   && source "$DOTFILES/aliases.sh"
[ -f "$DOTFILES/functions.sh" ] && source "$DOTFILES/functions.sh"

# Load extras (like conda, nvm, etc.)
for file in "$DOTFILES/extras/"*.sh; do
  [ -f "$file" ] && source "$file"
done

# Dotfiles main entry point — universal shell config (bash, zsh, future shells)
DOTFILES="${HOME}/.dotfiles/config/shell"

# Detect shell type for shell-specific branching downstream
export SHELL_TYPE="$(basename "$SHELL")"
# Safety net: version vars are more reliable than $SHELL for the running shell
[ -n "$ZSH_VERSION" ] && SHELL_TYPE="zsh"
[ -n "$BASH_VERSION" ] && SHELL_TYPE="bash"

[ -f "$DOTFILES/config.sh" ]    && source "$DOTFILES/config.sh"
[ -f "$DOTFILES/env.sh" ]       && source "$DOTFILES/env.sh"
[ -f "$DOTFILES/functions.sh" ] && source "$DOTFILES/functions.sh"
[ -f "$DOTFILES/aliases.sh" ]   && source "$DOTFILES/aliases.sh"

# Load extras (like conda, nvm, etc.)
for file in "$DOTFILES/extras/"*.sh; do
  [ -f "$file" ] && source "$file"
done

[ -f "$DOTFILES/post-init.sh" ] && source "$DOTFILES/post-init.sh"

# Clean up — downstream files use SHELL_TYPE, not DOTFILES
unset DOTFILES

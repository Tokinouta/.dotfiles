# Dotfiles main entry point — universal shell config (bash, zsh, future shells)
DOTFILES="${HOME}/.dotfiles/config/shell"

# Detect shell type for shell-specific branching downstream
if [ -n "$ZSH_VERSION" ]; then
  export SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
  export SHELL_TYPE="bash"
else
  # Fallback: try to guess from $SHELL or $0
  case "$(basename "${SHELL:-$0}")" in
    zsh)  export SHELL_TYPE="zsh" ;;
    bash) export SHELL_TYPE="bash" ;;
    *)    export SHELL_TYPE="unknown" ;;
  esac
fi

[ -f "$DOTFILES/config.sh" ]    && source "$DOTFILES/config.sh"
[ -f "$DOTFILES/env.sh" ]       && source "$DOTFILES/env.sh"
[ -f "$DOTFILES/aliases.sh" ]   && source "$DOTFILES/aliases.sh"
[ -f "$DOTFILES/functions.sh" ] && source "$DOTFILES/functions.sh"

# Load extras (like conda, nvm, etc.)
for file in "$DOTFILES/extras/"*.sh; do
  [ -f "$file" ] && source "$file"
done

# Clean up — downstream files use SHELL_TYPE, not DOTFILES
unset DOTFILES

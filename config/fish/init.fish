# Dotfiles main entry point — fish config (bash/zsh live in config/shell/)
# Fish cannot source POSIX scripts, so it gets its own parallel tree.
set -gx SHELL_TYPE fish

if status is-interactive
    set -l DOTFILES "$HOME/.dotfiles/config/fish"

    for file in env aliases functions
        test -f "$DOTFILES/$file.fish"; and source "$DOTFILES/$file.fish"
    end

    # Load extras (like conda, cargo, etc.)
    for file in "$DOTFILES"/extras/*.fish
        test -f "$file"; and source "$file"
    end

    test -f "$DOTFILES/post-init.fish"; and source "$DOTFILES/post-init.fish"
end

# These depend on anything being loaded before initializing themselves

# Starship prompt
command -q starship; and starship init fish | source

# zoxide init (defines z; aliases.fish maps cd to it)
command -q zoxide; and zoxide init fish | source

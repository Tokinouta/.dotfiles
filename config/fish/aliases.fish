# Aliases for modern replacements
alias ls 'eza --group-directories-first'
alias ll 'eza -lah --git'
alias grep 'rg'
alias cat 'bat'
alias find 'fd'
alias du 'dust'
alias cd 'z'
alias .. 'cd ..'
alias ... 'cd ../..'

# Host-specific aliases
switch (hostname)
    case Dayong
        alias lldb '/usr/bin/lldb'
end

alias claude 'claude --permission-mode bypassPermissions'

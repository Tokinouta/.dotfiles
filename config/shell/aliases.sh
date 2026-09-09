# Aliases for modern replacements
alias ls='eza --group-directories-first'
alias ll='eza -lah --git'
alias grep='rg'
alias cat='bat'
alias find='fd'
alias du='dust'
alias cd='z'
alias ..='cd ..'
alias ...='cd ../..'
alias claude='claude --permission-mode bypassPermissions'

# Host-specific aliases
case "$(hostname)" in
  Dayong)
    alias lldb=/usr/bin/lldb
    ;;
esac

# Shell-specific aliases
# zsh only: keep cc's math literal so cc (1+2)*3 works unquoted; bash has no noglob — quote there.
if [ "$SHELL_TYPE" = "zsh" ]; then
  alias cc='noglob cc'
fi


# General shell config (bash, zsh)

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
if [ "$SHELL_TYPE" = "bash" ]; then
  shopt -s histappend
elif [ "$SHELL_TYPE" = "zsh" ]; then
  setopt APPEND_HISTORY

  # macOS zsh defaults to vi-mode when $EDITOR contains "vi" (e.g. nvim),
  # breaking Ctrl-A/R/E/K etc. Force emacs keybindings.
  [ "$(uname -s)" = "Darwin" ] && bindkey -e
fi

# for setting history length
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
if [ "$SHELL_TYPE" = "bash" ]; then
  shopt -s checkwinsize
fi
# zsh handles window size automatically — no equivalent needed

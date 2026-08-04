export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Load shell-appropriate completion
if [ "$SHELL_TYPE" = "bash" ]; then
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
elif [ "$SHELL_TYPE" = "zsh" ]; then
  # nvm's zsh completion ships as part of nvm.sh itself on modern installs;
  # if a separate completion script exists, load it too.
  [ -s "$NVM_DIR/zsh_completion" ] && \. "$NVM_DIR/zsh_completion"
fi

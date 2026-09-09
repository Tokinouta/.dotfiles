export NVM_DIR="$HOME/.nvm"

# Lazy nvm: full init (nvm.sh + nvm_auto, ~500ms) is deferred until the first
# call to `nvm`, `node`, `npm`, or `npx`. The real nvm.sh manages PATH itself;
# no PATH pre-population to avoid duplicate entries on `nvm use`.
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _nvm_init() {
    unset -f _nvm_init nvm node npm npx 2>/dev/null
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }
  nvm()  { _nvm_init; nvm  "$@"; }
  node() { _nvm_init; command node "$@"; }
  npm()  { _nvm_init; command npm  "$@"; }
  npx()  { _nvm_init; command npx  "$@"; }
fi

# Extract files
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *)         echo "Cannot extract '$1'" ;;
  esac
}

# Cross-platform clear
cl() {
  command -v clear &>/dev/null && clear || printf "\033c"
}

# Check inotify watchers
check_inotify() {
  lsof | awk '/inotify$/ {print $1, $2}' | sort | uniq -c | sort -nr
}

# Calculator: python3 with math preloaded — cc 2**10, cc 'sqrt(16)'
# Uses the `function cc {}` keyword form (not `cc() {}`): zsh expands aliases while
# parsing `name() {}` definitions, so the `cc` alias defined below (or left over from
# a previous `source` of this file) would expand `cc()` into `noglob cc()` and raise
# "defining function based on alias" + "parse error near ()". The keyword form is not
# alias-expanded, so it survives re-sourcing and the double load (zprofile + zshrc).
function cc { python3 -c "from math import *; print($*);"; }
# zsh only: keep cc's math literal so cc (1+2)*3 works unquoted; bash has no noglob — quote there.
if [ "$SHELL_TYPE" = "zsh" ]; then
  alias cc='noglob cc'
fi

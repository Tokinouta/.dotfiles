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
cc() { python3 -c "from math import *; print($*);"; }
# zsh only: keep cc's math literal so cc (1+2)*3 works unquoted; bash has no noglob — quote there.
# Defined after the function on purpose: zsh expands aliases while parsing function
# definitions, so an `alias cc` defined earlier (e.g. in aliases.sh, which loads
# before this file) breaks the `cc() {` line above with a parse error.
if [ "$SHELL_TYPE" = "zsh" ]; then
  alias cc='noglob cc'
fi

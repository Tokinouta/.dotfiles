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


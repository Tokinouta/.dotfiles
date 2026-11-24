#!/usr/bin/env bash
# install.sh — Install dependencies for .dotfiles
#
# Scans dotfiles config for referenced tools and installs missing ones.
# For each missing dep, tries sources in priority order:
#   homebrew → cargo → pacman → AUR (yay)
#
# Usage:
#   ./install.sh                # install all missing deps
#   ./install.sh --dry-run      # preview only
#   ./install.sh --only brew    # install only homebrew packages
#   ./install.sh --skip conda   # skip conda installation

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { printf "${GREEN}[✓]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()   { printf "${RED}[✗]${NC} %s\n" "$*"; }
step()  { printf "\n${CYAN}═══ %s ═══${NC}\n" "$*"; }

DRY_RUN=false
ONLY_MODE=""
SKIP_CONDA=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --only)    ONLY_MODE="$2"; shift 2 ;;
    --skip)
      case "$2" in
        conda) SKIP_CONDA=true ;;
        *)     err "Unknown --skip target: $2"; exit 1 ;;
      esac
      shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--only brew|cargo|pkg] [--skip conda]"
      echo ""
      echo "Install missing dependencies for .dotfiles"
      echo "Install order: homebrew → cargo → pacman → AUR"
      exit 0 ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

OS="$(uname -s)"
ARCH="$(uname -m)"
IS_MACOS=false; IS_LINUX=false

case "$OS" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
  *)      err "Unsupported OS: $OS"; exit 1 ;;
esac

command -v brew   >/dev/null 2>&1 && HAS_BREW=true   || HAS_BREW=false
command -v pacman >/dev/null 2>&1 && HAS_PACMAN=true  || HAS_PACMAN=false
command -v yay    >/dev/null 2>&1 && HAS_YAY=true     || HAS_YAY=false
command -v cargo  >/dev/null 2>&1 && HAS_CARGO=true   || HAS_CARGO=false

info "Detected: OS=$OS, arch=$ARCH"
info "Available: brew=$HAS_BREW, cargo=$HAS_CARGO, pacman=$HAS_PACMAN, yay=$HAS_YAY"

have() { command -v "$1" >/dev/null 2>&1; }

# DEPS array format: "command:brew_pkg:cargo_pkg:pacman_pkg:aur_pkg:description"
# Use "-" to skip a source. Sources are tried sequentially (brew → cargo → pacman → AUR).
# Prefix a brew package with "cask/" to install it as a Homebrew cask.

DEPS=(
  # Core editors & viewers (env.sh, aliases.sh)
  "bat:bat:-:bat:-:file viewer (PAGER, cat alias)"
  "eza:eza:-:eza:eza:modern ls replacement"
  "fd:fd:-:fd:fd:fast find replacement"
  "dust:dust:-:dust:dust:disk usage tree viewer"
  "zoxide:zoxide:-:zoxide:zoxide:smart cd (z command)"

  # Shell prompt (env.sh)
  "starship:starship:-:starship:starship:cross-shell prompt"

  # Search (aliases.sh)
  "rg:ripgrep:-:ripgrep:-:fast grep replacement"

  # Editor (env.sh)
  "nvim:neovim:-:neovim:-:text editor"

  # JavaScript runtimes (env.sh, extras/bun.sh)
  "bun:bun:-:bun:bun-bin:fast JS runtime and package manager"
  "node:node:-:nodejs:-:JavaScript runtime (global npm CLIs land in brew's bin)"

  # Python (functions.sh:cc, scripts/vote)
  "python3:python:-:python:-:python runtime"

  # Shells (config/fish/)
  "fish:fish:-:fish:-:fish shell"

  # Android tools (scripts/device-info, scripts/skip-boot-guide)
  "adb:cask/android-platform-tools:-:android-tools:android-sdk-platform-tools:adb device bridge"

  # Archive tool (functions.sh)
  "unzip:unzip:-:unzip:-:zip extractor"

  # Script deps (scripts/update-zen, scripts/download_and_try_parse_issues.sh)
  "wget:wget:-:wget:-:file downloader"

  # Media (extras/brew.sh)
  "ffmpeg:ffmpeg-full:-:-:-:ffmpeg full codec support"

  # System tools (functions.sh:check_inotify)
  "lsof:lsof:-:lsof:-:list open files"
)

# Special deps get dedicated installers below instead of a package-name lookup.
# Format: "name:description"
SPECIAL_DEPS=(
  "conda:Miniconda / Anaconda (extras/conda.sh)"
  "zsh-autosuggestions:zsh plugin sourced by post-init.sh"
  "zsh-syntax-highlighting:zsh plugin sourced by post-init.sh"
)

# Same install locations post-init.sh probes, in the same order.
has_zsh_plugin() {
  local name="$1" p
  for p in "/usr/share/$name/$name.zsh" \
           "/opt/homebrew/share/$name/$name.zsh" \
           "/usr/local/share/$name/$name.zsh" \
           "$HOME/.zsh/$name/$name.zsh"; do
    [ -f "$p" ] && return 0
  done
  return 1
}

FOUND=()
MISSING=()
MISSING_SPECIAL=()

for dep in "${DEPS[@]}"; do
  IFS=':' read -r cmd brew_pkg cargo_pkg pacman_pkg aur_pkg desc <<< "$dep"
  if have "$cmd"; then
    FOUND+=("$cmd")
  else
    MISSING+=("$dep")
  fi
done

for dep in "${SPECIAL_DEPS[@]}"; do
  IFS=':' read -r name desc <<< "$dep"
  case "$name" in
    conda)
      [ "$SKIP_CONDA" = true ] && { warn "Skipping conda (--skip conda)"; continue; }
      if have conda || [ -d "$HOME/miniconda3" ] || [ -d "$HOME/anaconda3" ] || [ -d "/opt/miniconda3" ]; then
        FOUND+=("conda")
      else
        MISSING_SPECIAL+=("$dep")
      fi
      ;;
    zsh-*)
      # zsh-only plugins — nothing to check when zsh isn't installed
      have zsh || continue
      if has_zsh_plugin "$name"; then
        FOUND+=("$name")
      else
        MISSING_SPECIAL+=("$dep")
      fi
      ;;
  esac
done

echo ""
step "Dependency Check Summary"

[ ${#FOUND[@]} -gt 0 ] && info "Already installed: ${FOUND[*]}"

if [ ${#MISSING[@]} -eq 0 ] && [ ${#MISSING_SPECIAL[@]} -eq 0 ]; then
  info "All dependencies are installed!"
  exit 0
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  for dep in "${MISSING[@]}"; do
    IFS=':' read -r cmd _ _ _ _ desc <<< "$dep"
    warn "Missing: $cmd ($desc)"
  done
fi
if [ ${#MISSING_SPECIAL[@]} -gt 0 ]; then
  for dep in "${MISSING_SPECIAL[@]}"; do
    IFS=':' read -r name desc <<< "$dep"
    warn "Missing (special): $name ($desc)"
  done
fi

if [ "$DRY_RUN" = true ]; then
  echo ""
  info "Dry run complete. Run without --dry-run to install."
  exit 0
fi

# ── Source-resolved installer ─────────────────────────────────────────────────
# For each missing dep, try sources in priority order until one succeeds.

install_one() {
  local cmd="$1" brew_pkg="$2" cargo_pkg="$3" pacman_pkg="$4" aur_pkg="$5" desc="$6"

  local try_brew=true try_cargo=true try_pkg=true
  case "$ONLY_MODE" in
    brew)  try_cargo=false; try_pkg=false ;;
    cargo) try_brew=false;  try_pkg=false ;;
    pkg)   try_brew=false;  try_cargo=false ;;
  esac

  # "cask/<token>" installs a Homebrew cask (e.g. GUI apps, platform-tools)
  local brew_flag=""
  case "$brew_pkg" in
    cask/*) brew_flag="--cask"; brew_pkg="${brew_pkg#cask/}" ;;
  esac

  if [ "$try_brew" = true ] && [ "$HAS_BREW" = true ] && [ "$brew_pkg" != "-" ]; then
    info "Installing $cmd via homebrew ($brew_pkg)..."
    if brew install $brew_flag "$brew_pkg"; then
      return 0
    fi
    warn "brew install $brew_pkg failed, trying next source..."
  fi

  if [ "$try_cargo" = true ] && [ "$HAS_CARGO" = true ] && [ "$cargo_pkg" != "-" ]; then
    info "Installing $cmd via cargo ($cargo_pkg)..."
    if cargo install "$cargo_pkg"; then
      return 0
    fi
    warn "cargo install $cargo_pkg failed, trying next source..."
  fi

  if [ "$try_pkg" = true ] && [ "$HAS_PACMAN" = true ] && [ "$pacman_pkg" != "-" ]; then
    info "Installing $cmd via pacman ($pacman_pkg)..."
    if sudo pacman -S --noconfirm "$pacman_pkg"; then
      return 0
    fi
    warn "pacman install $pacman_pkg failed, trying next source..."
  fi

  if [ "$try_pkg" = true ] && [ "$HAS_YAY" = true ] && [ "$aur_pkg" != "-" ]; then
    info "Installing $cmd via AUR ($aur_pkg)..."
    if yay -S --noconfirm "$aur_pkg"; then
      return 0
    fi
    warn "yay install $aur_pkg failed"
  fi

  err "Failed to install $cmd — no available source succeeded"
  return 1
}

# ── Homebrew bootstrapper ─────────────────────────────────────────────────────

install_homebrew() {
  if [ "$HAS_BREW" = true ]; then
    return 0
  fi
  step "Installing Homebrew"
  if [ "$IS_MACOS" = true ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" && HAS_BREW=true
  elif [ "$IS_LINUX" = true ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && HAS_BREW=true
  fi
  info "Homebrew installed"
}

# ── Special installers ────────────────────────────────────────────────────────

install_conda() {
  step "Installing Miniconda"
  local installer_url
  case "$OS-$ARCH" in
    Darwin-arm64)  installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh" ;;
    Darwin-x86_64) installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh" ;;
    Linux-x86_64)  installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" ;;
    Linux-aarch64) installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh" ;;
    *)             err "No conda installer for $OS-$ARCH"; return 1 ;;
  esac
  local installer="/tmp/miniconda_installer.sh"
  curl -fsSL -o "$installer" "$installer_url"
  bash "$installer" -b -u -p "$HOME/miniconda3"
  rm -f "$installer"
  "$HOME/miniconda3/bin/conda" init bash
  "$HOME/miniconda3/bin/conda" init zsh
  info "Miniconda installed to ~/miniconda3"
}

install_zsh_plugin() {
  local name="$1"
  step "Installing zsh plugin: $name"
  if [ "$HAS_BREW" = true ]; then
    brew install "$name" && return 0
  fi
  if [ "$HAS_PACMAN" = true ]; then
    sudo pacman -S --noconfirm "$name" && return 0
  fi
  err "Failed to install $name — no available source succeeded"
  return 1
}

# ── Execution ─────────────────────────────────────────────────────────────────

# Bootstrap homebrew if any dep needs it and isn't restricted by --only
NEEDS_BREW=false
if [ ${#MISSING[@]} -gt 0 ]; then
  for dep in "${MISSING[@]}"; do
    IFS=':' read -r _ brew_pkg _ _ _ _ <<< "$dep"
    [ "$brew_pkg" != "-" ] && NEEDS_BREW=true && break
  done
fi
# zsh plugins come from brew on macOS, or pacman on Arch
if [ ${#MISSING_SPECIAL[@]} -gt 0 ] && [ "$HAS_PACMAN" = false ]; then
  for dep in "${MISSING_SPECIAL[@]}"; do
    IFS=':' read -r name _ <<< "$dep"
    case "$name" in
      zsh-*) NEEDS_BREW=true; break ;;
    esac
  done
fi
if [ "$NEEDS_BREW" = true ] && [ "$ONLY_MODE" != "cargo" ] && [ "$ONLY_MODE" != "pkg" ]; then
  install_homebrew
fi

# Install standard deps
if [ ${#MISSING[@]} -gt 0 ]; then
  step "Installing missing packages"
  FAILED=()
  for dep in "${MISSING[@]}"; do
    IFS=':' read -r cmd brew_pkg cargo_pkg pacman_pkg aur_pkg desc <<< "$dep"
    install_one "$cmd" "$brew_pkg" "$cargo_pkg" "$pacman_pkg" "$aur_pkg" "$desc" || FAILED+=("$cmd")
  done

  if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    err "Could not install: ${FAILED[*]}"
    [ "$HAS_BREW" = false ] && warn "Homebrew not available. Install it or use --only pkg."
    [ "$HAS_CARGO" = false ] && warn "Cargo not available. Install rustup first."
    [ "$HAS_PACMAN" = false ] && [ "$HAS_YAY" = false ] && warn "No system package manager found."
  fi
fi

# Install special deps
if [ ${#MISSING_SPECIAL[@]} -gt 0 ] && [ "$ONLY_MODE" = "" ]; then
  for dep in "${MISSING_SPECIAL[@]}"; do
    IFS=':' read -r name _ <<< "$dep"
    case "$name" in
      conda) install_conda ;;
      zsh-*) install_zsh_plugin "$name" ;;
    esac
  done
fi

echo ""
step "Installation Complete"
echo ""
echo "Restart your shell or run:"
echo "  source ~/.bashrc                # for bash"
echo "  source ~/.zshrc                 # for zsh"
echo "  source ~/.config/fish/config.fish  # for fish"

if [ "$SKIP_CONDA" = true ]; then
  warn "Conda skipped (--skip conda). Install manually if needed."
fi

# Common environment variables
export EDITOR=nvim
export PAGER=bat
export PATH="$HOME/.local/bin:$PATH"

# Expose scripts shipped with the dotfiles (e.g. update-zen.sh) as commands.
# Scripts here must be executable and self-contained — they are run, not sourced.
DOTFILES_ROOT="${HOME}/.dotfiles"
[ -d "$DOTFILES_ROOT/scripts" ] && export PATH="$DOTFILES_ROOT/scripts:$PATH"
unset DOTFILES_ROOT

# Android tools (Linux work PC only)
case "$(hostname)" in
  Dayong)
    export PATH=~/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin/:~/android-sdk-linux/platform-tools:~/android-sdk-linux/tools:~/android-sdk-linux/build-tools/33.0.0:~/installed_softwares/gdb-11-xiaomi/bin:$PATH
    # add go binary path to $PATH.
    export PATH=/home/dayong/go/bin/:$PATH
    ;;
esac

# modify rustup source and source cargo env
export RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# JavaScript runtimes: bun
BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# Starship prompt (shell-aware)
command -v starship >/dev/null && eval "$(starship init "$SHELL_TYPE")"

# zoxide init (shell-aware, only if installed)
command -v zoxide >/dev/null && eval "$(zoxide init "$SHELL_TYPE")"

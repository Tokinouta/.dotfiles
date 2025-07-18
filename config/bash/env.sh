# Common environment variables
export EDITOR=nvim
export PAGER=bat
export PATH="$HOME/.local/bin:$PATH"

# Android tools
export PATH=~/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin/:~/android-sdk-linux/platform-tools:~/android-sdk-linux/tools:~/android-sdk-linux/build-tools/33.0.0:~/installed_softwares/gdb-11-xiaomi/bin:$PATH

# modify rustup source and source cargo env
export RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
. "$HOME/.cargo/env"

# JavaScript runtimes: bun and deno
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
. "/home/dayong/.deno/env"

# Starship prompt
eval "$(starship init bash)"

# zoxide init (only if installed)
eval "$(zoxide init bash)"


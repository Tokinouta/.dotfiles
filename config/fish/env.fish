# Common environment variables
set -gx EDITOR nvim
set -gx PAGER bat

# Expose scripts shipped with the dotfiles (e.g. update-zen) as commands.
# Scripts here must be executable and self-contained — they are run, not sourced.
# fish_add_path --path prepends to $PATH only (no persistent fish_user_paths
# state) and is idempotent; calling in the same order as env.sh's
# `export PATH=x:$PATH` chain reproduces bash's final PATH order exactly.
fish_add_path --path ~/.local/bin
fish_add_path --path ~/.dotfiles/scripts

# Android tools (Linux work PC only)
switch (hostname)
    case Dayong
        fish_add_path --path ~/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin
        fish_add_path --path ~/android-sdk-linux/platform-tools
        fish_add_path --path ~/android-sdk-linux/tools
        fish_add_path --path ~/android-sdk-linux/build-tools/33.0.0
        fish_add_path --path ~/installed_softwares/gdb-11-xiaomi/bin
        # add go binary path to $PATH
        fish_add_path --path ~/go/bin
end

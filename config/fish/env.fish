# Common environment variables
set -gx EDITOR nvim
set -gx PAGER bat

# Expose scripts shipped with the dotfiles (e.g. update-zen) as commands.
# Scripts here must be executable and self-contained — they are run, not sourced.
# fish_add_path --path prepends to $PATH only (no persistent fish_user_paths
# state) and is idempotent. Single-entry exports in env.sh map to single
# calls; env.sh's grouped Android export maps to one multi-arg call that
# keeps the group's line order — reproducing bash's final PATH order exactly.
fish_add_path --path ~/.local/bin
fish_add_path --path ~/.dotfiles/scripts

# Android tools (Linux work PC only)
switch (hostname)
    case Dayong
        # env.sh prepends this group in one export, so keep the group's line
        # order with a single multi-arg call (argument order is preserved).
        fish_add_path --path ~/android-sdk-linux/ndk/28.0.13004108/toolchains/llvm/prebuilt/linux-x86_64/bin ~/android-sdk-linux/platform-tools ~/android-sdk-linux/tools ~/android-sdk-linux/build-tools/33.0.0 ~/installed_softwares/gdb-11-xiaomi/bin
        # add go binary path to $PATH
        fish_add_path --path ~/go/bin
end

# modify rustup source and add cargo to PATH
# (~/.cargo/env is POSIX; its only effect is this PATH entry)
set -gx RUSTUP_UPDATE_ROOT "https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
set -gx RUSTUP_DIST_SERVER "https://mirrors.tuna.tsinghua.edu.cn/rustup"
fish_add_path ~/.cargo/bin

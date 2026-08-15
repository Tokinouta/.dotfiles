#!/usr/bin/env bash

# modify rustup source and source cargo env
export RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

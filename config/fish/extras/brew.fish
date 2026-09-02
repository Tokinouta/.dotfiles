# Homebrew (macOS only) — brew shellenv emits POSIX syntax, so translate manually
if test (uname -s) = Darwin; and test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew"
    fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
    set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirror.nju.edu.cn/git/homebrew/brew.git"
    set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git"
    fish_add_path /opt/homebrew/opt/ffmpeg-full/bin
end

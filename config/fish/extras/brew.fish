# Homebrew (macOS: /opt/homebrew, Linux: /home/linuxbrew/.linuxbrew) — brew shellenv emits POSIX syntax, so translate manually
set -l brew_prefix
if test (uname -s) = Darwin; and test -x /opt/homebrew/bin/brew
    set brew_prefix /opt/homebrew
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
else if test (uname -s) = Linux; and test -x /home/linuxbrew/.linuxbrew/bin/brew
    set brew_prefix /home/linuxbrew/.linuxbrew
    set -gx HOMEBREW_REPOSITORY /home/linuxbrew/.linuxbrew/Homebrew
end
if test -n "$brew_prefix"
    set -gx HOMEBREW_PREFIX $brew_prefix
    set -gx HOMEBREW_CELLAR $brew_prefix/Cellar
    fish_add_path --path $brew_prefix/bin $brew_prefix/sbin
    set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.cernet.edu.cn/homebrew/brew.git"
    set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.cernet.edu.cn/homebrew/homebrew-core.git"
    fish_add_path --path $brew_prefix/opt/ffmpeg-full/bin
end

# Homebrew (macOS only)
if [ "$(uname -s)" = "Darwin" ] && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_BREW_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git"
  [ -d "/opt/homebrew/opt/ffmpeg-full/bin" ] && export PATH="/opt/homebrew/opt/ffmpeg-full/bin:$PATH"
fi

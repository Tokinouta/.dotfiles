# Homebrew (macOS: /opt/homebrew, Linux: /home/linuxbrew/.linuxbrew)
if [ "$(uname -s)" = "Darwin" ] && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  _brew_prefix=/opt/homebrew
elif [ "$(uname -s)" = "Linux" ] && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  _brew_prefix=/home/linuxbrew/.linuxbrew
fi
if [ -n "${_brew_prefix:-}" ]; then
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.cernet.edu.cn/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.cernet.edu.cn/homebrew/homebrew-core.git"
  [ -d "$_brew_prefix/opt/ffmpeg-full/bin" ] && export PATH="$_brew_prefix/opt/ffmpeg-full/bin:$PATH"
  unset _brew_prefix
fi

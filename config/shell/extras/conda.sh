# Lazy conda: the full shell hook is deferred until the first `conda` or `mamba`
# call (~350ms saved per startup). If conda's bin is not on PATH at all, stubs
# print an error and return.

# Host-specific conda paths
case "$(hostname)" in
  Dayong) CONDA_BASE="/home/dayong/workspace/others/miniconda3" ;;
  *)
    if [ -d "$HOME/miniconda3" ]; then
      CONDA_BASE="$HOME/miniconda3"
    elif [ -d "$HOME/anaconda3" ]; then
      CONDA_BASE="$HOME/anaconda3"
    elif [ -d "/opt/miniconda3" ]; then
      CONDA_BASE="/opt/miniconda3"
    else
      CONDA_BASE=""
    fi
    ;;
esac

if [ -n "$CONDA_BASE" ] && [ -d "$CONDA_BASE" ]; then
  export CONDA_EXE="$CONDA_BASE/bin/conda"
  export _CE_M=''
  export _CE_CONDA=''
  PATH="$CONDA_BASE/condabin:$PATH"

  _conda_init() {
    unset -f conda mamba 2>/dev/null
    __conda_setup="$("$CONDA_EXE" "shell.$SHELL_TYPE" 'hook' 2>/dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    elif [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
      . "$CONDA_BASE/etc/profile.d/conda.sh"
    fi
    unset __conda_setup CONDA_BASE
  }

  conda() { _conda_init; conda "$@"; }
  [ -x "$CONDA_BASE/bin/mamba" ] && mamba() { _conda_init; mamba "$@"; }
else
  unset CONDA_BASE
fi

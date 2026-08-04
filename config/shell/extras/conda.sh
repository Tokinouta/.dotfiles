# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!

# Host-specific conda paths
case "$(hostname)" in
  Dayong)
    CONDA_BASE="/home/dayong/workspace/others/miniconda3"
    ;;
  *)
    # macOS / other hosts — try common locations
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

if [ -n "$CONDA_BASE" ]; then
  __conda_setup="$("$CONDA_BASE/bin/conda" "shell.$SHELL_TYPE" 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
          . "$CONDA_BASE/etc/profile.d/conda.sh"
      else
          export PATH="$CONDA_BASE/bin:$PATH"
      fi
  fi
  unset __conda_setup
fi
unset CONDA_BASE
# <<< conda initialize <<<

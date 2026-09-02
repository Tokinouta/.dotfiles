# >>> conda initialize >>>
# Host-specific conda paths
set -l CONDA_BASE ""
switch (hostname)
    case Dayong
        set CONDA_BASE /home/dayong/workspace/others/miniconda3
    case '*'
        # macOS / other hosts — try common locations
        if test -d "$HOME/miniconda3"
            set CONDA_BASE "$HOME/miniconda3"
        else if test -d "$HOME/anaconda3"
            set CONDA_BASE "$HOME/anaconda3"
        else if test -d /opt/miniconda3
            set CONDA_BASE /opt/miniconda3
        end
end

# conda's official fish hook (same shape `conda init fish` generates)
if test -n "$CONDA_BASE"; and test -x "$CONDA_BASE/bin/conda"
    eval "$CONDA_BASE/bin/conda" "shell.fish" "hook" | source
end
# <<< conda initialize <<<

# nvm (Node.js version manager)
# bash/zsh source the real nvm.sh (extras/nvm.sh); nvm is a bash function
# library fish cannot source, so here we only reproduce its PATH effect:
# resolve the default alias to a concrete version and prepend its bin.
# Installing/switching versions stays a bash/zsh affair.
set -q NVM_DIR; or set -gx NVM_DIR ~/.nvm

if test -s $NVM_DIR/nvm.sh; and test -r $NVM_DIR/alias/default
    set -l nvm_default (string trim < $NVM_DIR/alias/default)

    # 'lts/*' aliases chain to a concrete version in their own alias file
    if string match -q 'lts/*' -- $nvm_default; and test -r $NVM_DIR/alias/$nvm_default
        set nvm_default (string trim < $NVM_DIR/alias/$nvm_default)
    end

    # installed versions, oldest → newest (sort -V is version-aware)
    set -l installed (command ls $NVM_DIR/versions/node/ 2>/dev/null | command sort -V)

    set -l nvm_version
    switch $nvm_default
        case node stable unstable    # special aliases: latest installed
            set nvm_version $installed[-1]
        case '*'                     # exact or partial version ('22', 'v22.11.0' — v optional)
            set -l re (string escape --style=regex -- $nvm_default)
            set nvm_version (string match -er -- "^v?$re(?:\.|\$)" $installed)[-1]
    end

    if test -d $NVM_DIR/versions/node/$nvm_version/bin
        fish_add_path --path $NVM_DIR/versions/node/$nvm_version/bin
    end
end

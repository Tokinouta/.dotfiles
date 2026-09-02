# Extract files
function extract
    switch $argv[1]
        case '*.tar.bz2'
            tar xjf $argv[1]
        case '*.tar.gz'
            tar xzf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*'
            echo "Cannot extract '$argv[1]'"
    end
end

# Cross-platform clear
function cl
    if type -q clear
        clear
    else
        printf '\033c'
    end
end

# Check inotify watchers
function check_inotify
    lsof | awk '/inotify$/ {print $1, $2}' | sort | uniq -c | sort -nr
end

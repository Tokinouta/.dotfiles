# ssh-graphical-env.fish — restore graphical session env for SSH logins
# Without DISPLAY, xdg-open fails with "no method available" (exit 3) and
# herdr Ctrl+click link opening silently does nothing (herdr issue #2903).
# Picks the X11/Xwayland socket owned by the current user (skips greeter/root).
if set -q SSH_CONNECTION; and not set -q DISPLAY
    for sock in /tmp/.X11-unix/X*
        if test -e $sock; and test -O $sock
            set -l xnum (string replace 'X' '' (basename $sock))
            set -gx DISPLAY ":$xnum"
            break
        end
    end
    if not set -q XDG_RUNTIME_DIR; and test -d /run/user/(id -u)
        set -gx XDG_RUNTIME_DIR /run/user/(id -u)
    end
    if not set -q DBUS_SESSION_BUS_ADDRESS; and test -S /run/user/(id -u)/bus
        set -gx DBUS_SESSION_BUS_ADDRESS unix:path=/run/user/(id -u)/bus
    end
end

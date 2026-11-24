# ssh-graphical-env.sh — restore graphical session env for SSH logins
# Without DISPLAY, xdg-open fails with "no method available" (exit 3) and
# herdr Ctrl+click link opening silently does nothing (herdr issue #2903).
# Picks the X11/Xwayland socket owned by the current user (skips greeter/root).
if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${DISPLAY:-}" ]; then
  for _sock in /tmp/.X11-unix/X*; do
    [ -e "$_sock" ] && [ -O "$_sock" ] || continue
    DISPLAY=":${_sock##*/X}"
    export DISPLAY
    break
  done
  unset _sock
  if [ -z "${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/$(id -u)" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  fi
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
  fi
fi

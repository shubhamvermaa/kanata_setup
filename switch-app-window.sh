#!/usr/bin/env bash
# Switch to or launch an application window via GNOME Shell D-Bus interface
# Usage: switch-app-window.sh <app_id> [launch_command...]

set -euo pipefail

APP_ID="${1:-}"
shift || true
# The remaining arguments "$@" form the launch command.

if [ -z "$APP_ID" ]; then
  echo "Usage: $0 <app_id> [launch_command...]" >&2
  exit 1
fi

# Try to cycle/focus via the Extension
RESULT=$(gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/shell/extensions/WindowCycler \
  --method org.gnome.Shell.Extensions.WindowCycler.CycleAppWindows \
  "$APP_ID" 2>/dev/null | grep -oP '\(\K\d+' || echo "-1")

# If no window found (0) or extension error (-1), launch the app
if [ "$RESULT" = "0" ] || [ "$RESULT" = "-1" ]; then
  if [ $# -gt 0 ]; then
    nohup bash -c "$*" >/tmp/switch-app.log 2>&1 &
  else
    gtk-launch "$APP_ID" >/tmp/switch-app.log 2>&1 &
  fi
fi

#!/usr/bin/env bash
set -euo pipefail

label="com.iguppp.glm-anthropic-shim"
dst="$HOME/Library/LaunchAgents/${label}.plist"

if launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
fi

rm -f "$dst"
echo "Uninstalled $label"

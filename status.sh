#!/usr/bin/env bash
set -euo pipefail

label="com.iguppp.glm-anthropic-shim"

if launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
  echo "LaunchAgent: loaded"
else
  echo "LaunchAgent: not loaded"
fi

if curl -fsS http://127.0.0.1:8787/health; then
  echo
else
  echo "Health: failed"
fi

#!/usr/bin/env bash
set -euo pipefail

label="com.iguppp.glm-anthropic-shim"
plist="$HOME/Library/LaunchAgents/${label}.plist"
health_url="http://127.0.0.1:8787/health"
domain="gui/$(id -u)/$label"

if state="$(launchctl print "$domain" 2>/dev/null)"; then
  echo "LaunchAgent: loaded"
  echo "$state" | awk '
    /state =/ && !seen_state++ { print "State: " $3 }
    /pid =/ && !seen_pid++ { print "PID: " $3 }
    /runs =/ && !seen_runs++ { print "Runs: " $3 }
    /last exit code =/ && !seen_exit++ { sub(/^[ \t]*/, ""); print }
  '
else
  echo "LaunchAgent: not loaded"
  if [ -f "$plist" ]; then
    echo "Plist: $plist"
    echo "Repair: ./install-launchagent.sh"
  else
    echo "Plist: missing"
    echo "Install: ./install-launchagent.sh"
  fi
fi

if curl -fsS "$health_url"; then
  echo
else
  echo "Health: failed"
  echo "Health URL: $health_url"
fi

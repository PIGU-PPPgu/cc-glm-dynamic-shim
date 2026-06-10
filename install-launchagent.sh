#!/usr/bin/env bash
set -euo pipefail

label="com.iguppp.glm-anthropic-shim"
root="$(cd "$(dirname "$0")" && pwd)"
node_bin="${NODE_BIN:-$(command -v node)}"
dst="$HOME/Library/LaunchAgents/${label}.plist"
logs="$HOME/Library/Logs/glm-anthropic-shim"

mkdir -p "$HOME/Library/LaunchAgents" "$logs/requests"
cat > "$dst" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${node_bin}</string>
    <string>${root}/server.mjs</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${root}</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PORT</key>
    <string>8787</string>
    <key>GLM_MODEL</key>
    <string>glm-5.1</string>
    <key>GLM_SHIM_THINKING</key>
    <string>enabled</string>
    <key>GLM_SHIM_LOG_DIR</key>
    <string>${logs}/requests</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${logs}/stdout.log</string>

  <key>StandardErrorPath</key>
  <string>${logs}/stderr.log</string>
</dict>
</plist>
PLIST

if launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/$label" >/dev/null 2>&1 || true
fi

launchctl bootstrap "gui/$(id -u)" "$dst"
launchctl enable "gui/$(id -u)/$label"
launchctl kickstart -k "gui/$(id -u)/$label"

echo "Installed and started $label"
echo "Health: http://127.0.0.1:8787/health"

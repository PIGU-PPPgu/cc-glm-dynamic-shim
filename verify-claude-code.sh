#!/usr/bin/env bash
set -euo pipefail

settings="${1:-}"

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude CLI not found." >&2
  exit 1
fi

if ! curl -fsS http://127.0.0.1:8787/health >/dev/null; then
  echo "ERROR: shim is not healthy at http://127.0.0.1:8787/health" >&2
  exit 1
fi

if [ -n "$settings" ]; then
  claude --settings "$settings" -p "Reply exactly OK." --max-turns 1 --output-format text
else
  claude -p "Reply exactly OK." --max-turns 1 --output-format text
fi

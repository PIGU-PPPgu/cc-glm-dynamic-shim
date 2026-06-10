#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export GLM_MODEL="${GLM_MODEL:-glm-5.1}"
export GLM_SHIM_THINKING="${GLM_SHIM_THINKING:-enabled}"
export PORT="${PORT:-8787}"

exec npm start

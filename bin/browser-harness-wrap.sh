#!/bin/sh
# Enforces isolated automation Chrome (see docs/isolated-chrome.md).
# Re-apply after `uv tool upgrade browser-harness` — it overwrites this shim:
#   cp <this-script> ~/.local/bin/browser-harness
BU_CDP_URL="${BU_CDP_URL:-http://127.0.0.1:9333}"
export BU_CDP_URL
exec "$(dirname "$0")/browser-harness.uv" "$@"

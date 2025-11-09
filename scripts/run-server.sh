#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8000}"
DMB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMB="$DMB_DIR/Marrow.dmb"

if [[ ! -f "$DMB" ]]; then
  echo "Marrow.dmb not found at $DMB. Compile Marrow.dme first." >&2
  exit 1
fi

if [[ -n "${BYOND_HOME:-}" && -f "$BYOND_HOME/bin/byondsetup" ]]; then
  # shellcheck disable=SC1090
  . "$BYOND_HOME/bin/byondsetup"
fi

exec DreamDaemon "$DMB" "$PORT" -trusted -invisible -logself

#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8000}"
DMB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMB="$DMB_DIR/Interpost-Hague.dmb"
PUBLIC_HOST="${PUBLIC_HOST:-}"

if [[ ! -f "$DMB" ]]; then
  echo "Interpost-Hague.dmb not found at $DMB. Compile Interpost-Hague.dme first." >&2
  exit 1
fi

if [[ -n "${BYOND_HOME:-}" && -f "$BYOND_HOME/bin/byondsetup" ]]; then
  # shellcheck disable=SC1090
  . "$BYOND_HOME/bin/byondsetup"
fi

if [[ -z "$PUBLIC_HOST" ]] && command -v curl >/dev/null 2>&1; then
  PUBLIC_HOST="$(curl --fail --silent --max-time 5 https://api4.ipify.org 2>/dev/null || true)"
fi

DreamDaemon "$DMB" "$PORT" -trusted -invisible -logself 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" == *"World opened on network port "* ]]; then
    if [[ -n "$PUBLIC_HOST" ]]; then
      printf '\n==> Server ready. Connect with Dream Seeker: byond://%s:%s\n' "$PUBLIC_HOST" "$PORT"
    else
      printf '\n==> Server ready, but the public address could not be detected. Set PUBLIC_HOST to override.\n'
    fi
  fi
done

exit "${PIPESTATUS[0]}"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

LOCK_DIR="$ROOT_DIR/.run-menubar.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Launcher already running. Try again in a few seconds."
  exit 1
fi
trap 'rmdir "$LOCK_DIR"' EXIT

if pgrep -x "ConflictMonitor" >/dev/null 2>&1; then
  echo "Restarting existing ConflictMonitor instance..."
  pkill -x "ConflictMonitor" || true
  for _ in {1..20}; do
    if ! pgrep -x "ConflictMonitor" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
fi

echo "Launching ConflictMonitor via Tuist..."
TUIST_SKIP_UPDATE_CHECK=1 tuist run ConflictMonitor "$@"

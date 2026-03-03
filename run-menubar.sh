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

# Generate only when needed, and never open Xcode from the script.
if [[ ! -d "ConflictMonitor.xcworkspace" || "Project.swift" -nt "ConflictMonitor.xcworkspace" ]]; then
  TUIST_SKIP_UPDATE_CHECK=1 tuist generate --no-open >/dev/null
fi
TUIST_SKIP_UPDATE_CHECK=1 tuist build ConflictMonitor --configuration Debug >/dev/null

BUILD_SETTINGS="$(xcodebuild -workspace ConflictMonitor.xcworkspace -scheme ConflictMonitor -configuration Debug -showBuildSettings 2>/dev/null)"
TARGET_BUILD_DIR="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/TARGET_BUILD_DIR/ {print $2; exit}')"
FULL_PRODUCT_NAME="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/FULL_PRODUCT_NAME/ {print $2; exit}')"

if [[ -z "${TARGET_BUILD_DIR:-}" || -z "${FULL_PRODUCT_NAME:-}" ]]; then
  echo "Failed to resolve app path from build settings" >&2
  exit 1
fi

APP_PATH="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at: $APP_PATH" >&2
  exit 1
fi

open "$APP_PATH"
echo "Launched in menu bar: $APP_PATH"

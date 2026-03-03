# ConflictMonitor Agent Guide

All docs must be canonical, with no past commentary, only live state.

## Scope

This file is the agent contract for how to work in this repo.

Primary references:

- `README.md` (setup + run workflow)
- `Project.swift` (Tuist manifest + target config)
- `run-menubar.sh` (canonical local launch flow)

## Project Snapshot

ConflictMonitor is a lightweight macOS menubar app that displays the latest events from:

- `https://monitor-the-situation.com/api/events`

Current stack:

- App UI/runtime: SwiftUI (`ConflictMonitor/Sources/*`)
- Build/generation: Tuist (`Project.swift`)
- Launch workflow: shell launcher (`run-menubar.sh`)

## Non-Negotiable Architecture Rules

1. Keep the app menubar-only (`LSUIElement = true`) unless a product decision explicitly changes it.
2. Keep network logic in dedicated client/store files, not embedded in view bodies.
3. Keep decoding models resilient to API changes (optional fields where appropriate).
4. Keep view composition simple: app entry -> menu view -> row/subviews.
5. Avoid adding Xcode-only workflow requirements; Tuist + scripts remain primary.

## Routing Rules (Code Placement)

For changes to API behavior:

1. `ConflictMonitor/Sources/EventsClient.swift` (request/response handling)
2. `ConflictMonitor/Sources/ConflictEvent.swift` (model decoding/mapping)
3. `ConflictMonitor/Sources/EventStore.swift` (state/update policy)
4. `ConflictMonitor/Sources/EventsMenuView.swift` and related views

For UI behavior:

1. `ConflictMonitor/Sources/ConflictMonitorApp.swift` (scene wiring only)
2. `ConflictMonitor/Sources/EventsMenuView.swift` (popup state/layout)
3. `ConflictMonitor/Sources/EventRowView.swift` (event row presentation)

## Key File Anchors

- Tuist manifest: `Project.swift`
- App entrypoint: `ConflictMonitor/Sources/ConflictMonitorApp.swift`
- API client: `ConflictMonitor/Sources/EventsClient.swift`
- Event model: `ConflictMonitor/Sources/ConflictEvent.swift`
- State/store: `ConflictMonitor/Sources/EventStore.swift`
- Popup UI: `ConflictMonitor/Sources/EventsMenuView.swift`
- Row UI: `ConflictMonitor/Sources/EventRowView.swift`
- Launch script: `run-menubar.sh`

## Runtime and Launch Invariants

- `run-menubar.sh` is the canonical run path.
- The launcher must restart an existing app instance before launching a new one.
- The launcher must not open Xcode (`tuist generate --no-open` behavior).
- Do not depend on `tuist run` as primary launch flow in this repo.

## Safety and Git Behavior

- Prefer safe git operations (`status`, `diff`, `log`).
- Do not reset/revert unrelated user changes.
- If unrelated changes appear, continue focusing on owned files unless they block correctness.
- Fix root cause, not temporary UI-only band-aids.

## Validation Matrix

Run validations based on touched areas:

- Always after changes: `TUIST_SKIP_UPDATE_CHECK=1 tuist build ConflictMonitor --configuration Debug`
- If launch workflow changed: run `./run-menubar.sh` at least once
- If scripts changed: run with `bash -n <script>` and one real execution

## Quick Runbook

```bash
# Build only
TUIST_SKIP_UPDATE_CHECK=1 tuist build ConflictMonitor --configuration Debug

# Canonical local run (restart + build + launch menubar app)
./run-menubar.sh
```

## Hotspots

Use extra care in these files:

- `run-menubar.sh`
- `Project.swift`
- `ConflictMonitor/Sources/EventsClient.swift`
- `ConflictMonitor/Sources/EventStore.swift`
- `ConflictMonitor/Sources/EventsMenuView.swift`


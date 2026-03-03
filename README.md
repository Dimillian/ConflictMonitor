![Screenshot](assets/screenshot-2026-03-03-13-34-48.png)

# ConflictMonitor

Small macOS menubar app built with Tuist that shows the latest events from:

- `https://monitor-the-situation.com/api/events`

## Requirements

- macOS 13+
- Tuist installed (`tuist version`)

## Run

```bash
./run-menubar.sh
```

Or directly with Tuist:

```bash
tuist run ConflictMonitor
```

The app runs as a menubar-only app (`LSUIElement = true`), so you will see its icon in the macOS menu bar.
Running `./run-menubar.sh` again will stop the current instance and relaunch it.

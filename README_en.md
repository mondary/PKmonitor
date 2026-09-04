# PKMonitor

[FR](README.md) · [EN](README_en.md)

Native macOS system monitor in the menu bar. Real-time sparkline, clickable
GPU/CPU/RAM/NET gauges, responsible app details with force kill, and full settings.

## Features

- Real-time sparkline (200 ms default, configurable)
- CPU, GPU, RAM and network measurements (separate download/upload)
- Four clickable gauges to switch displayed metric
- Dominant app icons on the curve
- Detail on hover with terminate (SIGTERM) or force kill (SIGKILL)
- Activity Monitor filtered by PID
- Configurable color thresholds (warning/critical)
- Vertical label and gauges positionable (left/right)
- Launch at login
- Icon location: menu bar or customizable second bar (right-aligned pill: None/Tint/Hover/Blur background, free color, 4-side padding, light/dark/auto content)
- Light/dark/system theme

## Usage

- Hover: open details below the menu bar
- Left-click: pin/unpin the panel
- Right-click: context menu with metrics and settings
- Click on a gauge: switch to that metric
- ✕ button: quit the process (SIGTERM)
- 💀 button: force kill (SIGKILL)

## Settings

The Settings window (right-click > Settings…) provides:

- **General**: refresh rate, history, icon count, hover, icon location, launch at login, color thresholds
- **Appearance**: sparkline width/thickness, icon size, border, text and gauge position, theme
- **About**: version and info

## Build & Package

```sh
chmod +x run.sh
./run.sh
```

The script builds `dist/PKMonitor.app` and launches it. Requires macOS 13+ and
Xcode command-line tools.

## See [CHANGELOG](CHANGELOG.md) for full history.

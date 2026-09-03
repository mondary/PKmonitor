# PKMonitor

[FR](README.md) · [EN](README_en.md)

Native macOS prototype inspired by ActivityLine. It displays a sparkline and a
live system metric in the menu bar. Dominant application icons appear on spikes
and move with the history without sending measurements off the Mac.

## Run

```sh
chmod +x run.sh
./run.sh
```

The script builds `dist/PKMonitor.app` and launches it. It requires macOS 13 or
newer and the Xcode command-line tools.

## Usage

- Hover or left-click: open details below the menu bar.
- Right-click: select a metric, enable launch at login, or quit.
- The metric name is stacked vertically in the menu bar.
- Each application can be located in Activity Monitor or terminated after confirmation.

CPU, RAM, and network use local system APIs. macOS has no stable public GPU
usage API, so GPU mode displays `N/A` in this prototype.

See [CHANGELOG](CHANGELOG.md) for full history.

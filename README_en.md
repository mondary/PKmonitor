# PKMonitor

![PKMonitor — CPU, GPU, RAM, network and disk in the menu bar](store/assets/banner-1544x500.png)

[🇫🇷 FR](README.md) · [🇬🇧 EN](README_en.md)

A native, focused macOS system monitor in the menu bar.

Version `2026.09.20` · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

![The menu bar and the second bar](store/screenshots/01-barre-et-seconde-barre.png)

![The hover detail panel](store/screenshots/02-panneau-detail.png)

## ✅ Features

- Real-time sparkline with dominant application icons
- CPU, GPU, RAM, network and disk space
- Two-line disk module: total capacity in red, free space in blue
- Individually enabled, reorderable and configurable segments
- Other apps' menu bar icons lowered into the second bar (Bartender-style)
- Display toggles for Sparkline, Gauges and Panel
- Hover detail panel with process termination controls and a settings button
- Categorized Settings navigation, search and project library
- Light/dark/system theme and launch at login

## 🧠 Usage

- Hover the menu bar item to open details
- Click a segment to change the active metric
- Click a lowered icon to open its original menu
- Right-click to open the menu and Settings

## ⚙️ Settings

The Settings window provides a categorized sidebar, search, per-module display toggles and detailed controls for the display, gauges, panel and sparkline. It also includes Help & Support and Project Library sections.

## 🧾 Commands

```sh
./run.sh
swift build
swift run PKMonitor --self-test
```

## 📦 Build & Package

`run.sh` builds `dist/PKMonitor.app` in production mode using the Xcode command-line tools.

## 🧪 Installation

Requires macOS 13+ and the Xcode command-line tools. Run `./run.sh`, then keep `dist/PKMonitor.app` or copy it to Applications.

## 📋 History

See the [CHANGELOG](CHANGELOG.md) for full history.

## 🔗 Links

- [GitHub](https://github.com/mondary/PKmonitor)
- [Project library](https://github.com/mondary?tab=repositories)
- [Ko-fi](https://ko-fi.com/pouark)
- [Store copy](store/description-store.md)

# PKMonitor

![PKMonitor icon](icon.png)

[🇫🇷 FR](README.md) · [🇬🇧 EN](README_en.md)

❤️ [Support PK Monitor on Ko-fi](https://ko-fi.com/pouark)

A native, focused macOS system monitor in the menu bar.

Version `2026.10.21` · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)

![PK Monitor settings window](store/screenshots/01-reglages.png)

## ✅ Features

- Real-time sparkline with dominant application icons
- CPU, GPU, RAM, network and disk space, with a customizable base and critical color for each gauge
- Configurable disk module: red total and blue free/available space, one or two lines with adjustable line spacing, adjustable position and size
- Individually enabled, reorderable and configurable segments
- Other apps' menu bar icons lowered into the second bar (Bartender-style)
- Display toggles for Sparkline, Gauges and Panel
- Hover detail panel with process termination controls and a settings button
- Categorized Settings navigation, search and project library
- AI Advisor as a resizable side panel (right, left or bottom): table of heavy processes, estimated legitimacy, alert rationale and recommendations, via any OpenAI-compatible endpoint
- Light/dark/system theme and launch at login

## 🧠 Usage

- Hover the menu bar item to open details
- Click a segment to change the active metric
- Click a lowered icon to open its original menu
- Right-click to open the menu and Settings
- Click the AI button in the detail panel to analyze what is consuming resources and get advice

## ⚙️ Settings

The Settings window provides a live system dashboard (hardware and metrics), a categorized sidebar, search and one tab per module: sparkline, gauges, disk, panel, menu bar icons and the AI advisor (OpenAI-compatible endpoint, panel or window placement, Keychain API key and user-triggered analysis). It also includes Help & Support and Project Library sections.

## 🧾 Commands

```sh
./packaging/run.sh
swift build
swift run PKMonitor --self-test
```

## 📦 Build & Package

`packaging/run.sh` builds `dist/PKMonitor.app` in production mode using the Xcode command-line tools.

## 🌐 Product page

The bilingual landing page source is [`store/index.html`](store/index.html). Run `sh scripts/website.sh` to generate the standalone FTP bundle in `store/website/`; it contains `index.html` directly and can be uploaded as-is. Download links resolve the latest release through GitHub's public API.

## 🧪 Installation

Requires macOS 13+ and the Xcode command-line tools. Run `./packaging/run.sh`, then keep `dist/PKMonitor.app` or copy it to Applications.

## 📋 History

See the [CHANGELOG](CHANGELOG.md) for full history.

## 🔗 Links

- [GitHub](https://github.com/mondary/PKmonitor)
- [Project library](https://github.com/mondary?tab=repositories)
- [Store copy](store/description-store.md)

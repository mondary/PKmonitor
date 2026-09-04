#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"

swift build --package-path "$ROOT" -c release --disable-index-store
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/PKMonitor" "$APP/Contents/MacOS/PKMonitor"
mkdir -p "$APP/Contents/Resources/ProjectIcons"
cp "$ROOT/icon.png" "$APP/Contents/Resources/icon.png"
cp "$ROOT/ProjectIcons/"*.png "$APP/Contents/Resources/ProjectIcons/"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>PKMonitor</string>
  <key>CFBundleIdentifier</key><string>com.mondary.pkmonitor</string>
  <key>CFBundleName</key><string>PKMonitor</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF

echo "Built $APP"

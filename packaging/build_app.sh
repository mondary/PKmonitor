#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
VERSION=$(sed -nE 's/^##? \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "$ROOT/CHANGELOG.md" | sed -n '1p')
test -n "$VERSION" || { echo "Could not read version from CHANGELOG.md" >&2; exit 1; }
APP="$ROOT/dist/PKMonitor.app"

swift build --package-path "$ROOT" -c release --disable-index-store
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/PKMonitor" "$APP/Contents/MacOS/PKMonitor"
# Frameworks binaires SPM (Sparkle) embarques dans le bundle.
mkdir -p "$APP/Contents/Frameworks"
for fw in "$ROOT"/.build/release/*.framework; do
  [ -d "$fw" ] || continue
  cp -R "$fw" "$APP/Contents/Frameworks/"
done
if [ -n "$(ls -A "$APP/Contents/Frameworks" 2>/dev/null)" ]; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/PKMonitor" 2>/dev/null || true
fi
mkdir -p "$APP/Contents/Resources/ProjectIcons"
cp "$ROOT/packaging/icons/icon.png" "$APP/Contents/Resources/icon.png"
cp "$ROOT/src/macos/Resources/kofi-logo.png" "$APP/Contents/Resources/kofi-logo.png"
cp "$ROOT/src/macos/Resources/ProjectIcons/"*.png "$APP/Contents/Resources/ProjectIcons/"
mkdir -p "$APP/Contents/Resources/ProjectScreenshots"
cp "$ROOT/src/macos/Resources/ProjectScreenshots/"*.png "$APP/Contents/Resources/ProjectScreenshots/"

cp "$ROOT/packaging/icons/icon.icns" "$APP/Contents/Resources/icon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>PKMonitor</string>
  <key>CFBundleIdentifier</key><string>com.mondary.pkmonitor</string>
  <key>CFBundleName</key><string>PKMonitor</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>SUFeedURL</key><string>https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast.xml</string>
  <key>SUPublicEDKey</key><string>OoygS0py6kkvRJBB8QAXiAli30SXSYvV7V54Z0Gtcj0=</string>
  <key>SUEnableInstallerLauncherService</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF

echo "Built $APP"

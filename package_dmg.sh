#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/PKMonitor-$VERSION.dmg"
BACKGROUND="$ROOT/packaging/dmg-background.gif"

"$ROOT/build_app.sh"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/PKMonitor.app"

# Contrat dmgly (create-dmg) : fenêtre stylée, fond animé, app -> Applications.
if command -v create-dmg >/dev/null 2>&1 && [ -f "$BACKGROUND" ]; then
  if ! create-dmg \
      --volname "PKMonitor $VERSION" \
      --window-size 660 400 \
      --icon-size 128 \
      --icon "PKMonitor.app" 180 170 \
      --app-drop-link 480 170 \
      --hide-extension "PKMonitor.app" \
      --background "$BACKGROUND" \
      "$DMG" "$STAGE"; then
    rm -f "$DMG"
    hdiutil create \
      -volname "PKMonitor $VERSION" \
      -srcfolder "$STAGE" \
      -format UDZO \
      -imagekey zlib-level=9 \
      "$DMG"
  fi
else
  ln -s /Applications "$STAGE/Applications"
  hdiutil create \
    -volname "PKMonitor $VERSION" \
    -srcfolder "$STAGE" \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG"
fi

rm -rf "$STAGE"
echo "Built $DMG"

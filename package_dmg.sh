#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/PKMonitor-$VERSION.dmg"

"$ROOT/build_app.sh"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/PKMonitor.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "PKMonitor $VERSION" \
  -srcfolder "$STAGE" \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG"

rm -rf "$STAGE"
echo "Built $DMG"

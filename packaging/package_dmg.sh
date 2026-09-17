#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/PKMonitor-$VERSION.dmg"
BACKGROUND="$ROOT/packaging/dmg-background.gif"

"$ROOT/packaging/build_app.sh"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/PKMonitor.app"

# Contrat dmgly (create-dmg) : fenêtre stylée, fond animé, app -> Applications.
# create-dmg vendorisé d'abord (standalone), sinon brew, sinon repli hdiutil.
CDMG=""
if [ -x "$ROOT/packaging/vendor/create-dmg/create-dmg" ]; then
  CDMG="$ROOT/packaging/vendor/create-dmg/create-dmg"
elif command -v create-dmg >/dev/null 2>&1; then
  CDMG="create-dmg"
fi
if [ -n "$CDMG" ] && [ -f "$BACKGROUND" ]; then
  if ! "$CDMG" \
      --volname "PKMonitor $VERSION" \
      --window-size 660 494 \
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

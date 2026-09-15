#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/PKMonitor-$VERSION.dmg"
BG1X="$ROOT/packaging/dmg-background.png"
BG2X="$ROOT/packaging/dmg-background@2x.png"

"$ROOT/build_app.sh"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/PKMonitor.app"

# dmgly-style packaging via dmgbuild: DS_Store forge sans Finder
# (sidebar/toolbar off, fenetre exacte, fond 1x+@2x combine en TIFF Retina).
if python3 -c 'import dmgbuild' >/dev/null 2>&1 && [ -f "$BG1X" ] && [ -f "$BG2X" ]; then
  python3 - "$DMG" "$VERSION" "$STAGE" "$BG1X" <<'PY'
import sys, dmgbuild
dmg, version, stage, bg = sys.argv[1:5]
dmgbuild.build_dmg(dmg, f"PKMonitor {version}", settings={
    "filename": dmg,
    "format": "UDZO",
    "compression_level": 9,
    "files": [f"{stage}/PKMonitor.app"],
    "symlinks": {"Applications": "/Applications"},
    "icon_size": 128,
    "icon_locations": {"PKMonitor.app": (180, 170), "Applications": (480, 170)},
    "background": bg,
    "window_rect": ((200, 200), (660, 428)),
    "default_view": "icon-view",
    "show_status_bar": False,
    "show_toolbar": False,
    "show_sidebar": False,
    "show_tab_view": False,
})
PY
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

#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
APP="$ROOT/dist/PKMonitor.app"
STAGE="$ROOT/dist/dmg-stage"
RAW="$ROOT/dist/PKMonitor-raw.dmg"
RW="$ROOT/dist/PKMonitor-rw.dmg"
DMG="$ROOT/dist/PKMonitor-$VERSION.dmg"
BG="$ROOT/packaging/dmg-background.png"
VOL="PKMonitor $VERSION"

"$ROOT/build_app.sh"
rm -rf "$STAGE" "$RAW" "$RW" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/PKMonitor.app"

if python3 -c 'import dmgbuild' >/dev/null 2>&1 && [ -f "$BG" ]; then
  # 1. Squelette dmgbuild : bwsp moderne (sidebar off, bornes respectees par Finder).
  python3 - "$RAW" "$VOL" "$STAGE" <<'PY'
import sys, dmgbuild
raw, vol, stage = sys.argv[1:4]
dmgbuild.build_dmg(raw, vol, settings={
    "filename": raw,
    "format": "UDRW",
    "files": [f"{stage}/PKMonitor.app"],
    "symlinks": {"Applications": "/Applications"},
    "icon_size": 128,
    "icon_locations": {"PKMonitor.app": (180, 170), "Applications": (480, 170)},
    "window_rect": ((200, 200), (660, 428)),
    "default_view": "icon-view",
    "show_status_bar": False,
    "show_toolbar": False,
    "show_sidebar": False,
    "show_tab_view": False,
})
PY

  # 2. Montage RW + passe Finder : fond pose par Finder (alias resolvable),
  #    positions reaffirmees, .DS_Store ecrit par Finder lui-meme.
  ATTACH=$(hdiutil attach -readwrite -noverify -noautoopen -nobrowse "$RAW")
  DEV=$(printf '%s\n' "$ATTACH" | grep '^/dev/' | sed 1q | awk '{print $1}')
  MNT=$(printf '%s\n' "$ATTACH" | tail -1 | cut -f3)
  mkdir -p "$MNT/.background"
  cp "$BG" "$MNT/.background/dmg-background.png"
  osascript - "$VOL" "$MNT" <<'AS' >/dev/null
on run argv
  set volName to item 1 of argv
  set mntPath to item 2 of argv
  set bgFile to (POSIX file (mntPath & "/.background/dmg-background.png")) as alias
  tell application "Finder"
    tell disk (volName as string)
      open
      tell container window
        set current view to icon view
        set toolbar visible to false
        set statusbar visible to false
        set bounds to {200, 200, 860, 628}
      end tell
      set opts to the icon view options of container window
      tell opts
        set icon size to 128
        set arrangement to not arranged
        set background picture to bgFile
      end tell
      set position of item "PKMonitor.app" of container window to {116, 106}
      set position of item "Applications" of container window to {416, 106}
      close
      open
      delay 2
      close
    end tell
  end tell
end run
AS
  sleep 2
  hdiutil detach "$DEV" >/dev/null

  # 3. Conversion finale UDZO.
  hdiutil convert "$RAW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
  rm -f "$RAW" "$RW"
else
  ln -s /Applications "$STAGE/Applications"
  hdiutil create \
    -volname "$VOL" \
    -srcfolder "$STAGE" \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG"
fi

rm -rf "$STAGE"
echo "Built $DMG"

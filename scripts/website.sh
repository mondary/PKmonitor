#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SOURCE="$ROOT/store/website/index.html"
TARGET="$ROOT/store/website/pkmonitor"

if [ ! -f "$SOURCE" ]; then
  echo "Missing landing page: $SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET"
cp "$SOURCE" "$TARGET/index.html"
echo "FTP-ready landing generated at $TARGET"

#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
sh "$ROOT/packaging/build_app.sh"
open "$ROOT/dist/PKMonitor.app"

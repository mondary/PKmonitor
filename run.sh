#!/bin/sh
set -eu
"$(dirname "$0")/build_app.sh"
open "$(dirname "$0")/dist/PKMonitor.app"

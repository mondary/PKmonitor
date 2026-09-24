(
  set -eu
  pkm_target="$HOME/Applications/PKMonitor.app"
  if [ -e "$pkm_target" ] || [ -e /Applications/PKMonitor.app ]; then
    printf '%s\n' 'PK Monitor est déjà installé. Utilisez le DMG pour le mettre à jour.'
    exit 0
  fi
  pkm_tmp="$(mktemp -d "${TMPDIR:-/tmp/}pkmonitor.XXXXXX")"
  trap 'hdiutil detach "$pkm_tmp/volume" >/dev/null 2>&1 || true; rm -rf "$pkm_tmp"' EXIT
  curl -fL '@@DMG_URL@@' -o "$pkm_tmp/PKMonitor.dmg"
  mkdir "$pkm_tmp/volume"
  hdiutil attach -nobrowse -readonly -mountpoint "$pkm_tmp/volume" "$pkm_tmp/PKMonitor.dmg" >/dev/null
  test -d "$pkm_tmp/volume/PKMonitor.app"
  mkdir -p "$HOME/Applications"
  ditto "$pkm_tmp/volume/PKMonitor.app" "$pkm_target"
  open "$pkm_target"
)

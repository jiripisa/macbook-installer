# shellcheck shell=bash
# Xcode is installed by hand from the App Store; once it is there, this sets
# it up for command-line builds and fetches the iPhone simulator.

MBI_APPS_DIR="${MBI_APPS_DIR:-/Applications}"

setup_xcode() {
  local xcode="$MBI_APPS_DIR/Xcode.app" dev
  if [ ! -d "$xcode" ]; then
    warn "Xcode zatím není nainstalovaný."
    note_todo "Nainstaluj Xcode z App Store (vyhledej „Xcode“, je zdarma a má přes 10 GB). Pak tenhle skript spusť znovu a Xcode se nastaví."
    return 0
  fi
  dev="$xcode/Contents/Developer"
  if [ "$(xcode-select -p 2>/dev/null)" != "$dev" ]; then
    sudo xcode-select -s "$dev"
  fi
  sudo xcodebuild -license accept
  sudo xcodebuild -runFirstLaunch
  ok "Xcode je nastavený pro práci z terminálu"
  if ! xcrun simctl list runtimes 2>/dev/null | grep -q '^iOS'; then
    info "Stahuju simulátor iPhonu (několik GB, chvíli to potrvá)…"
    xcodebuild -downloadPlatform iOS
    ok "Simulátor iPhonu je stažený"
  fi
  note_installed "Xcode nastavení a simulátor iPhonu"
}

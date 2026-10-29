# shellcheck shell=bash
# Homebrew itself plus the formulae the GitHub step needs right away.

MBI_BREW_BIN="${MBI_BREW_BIN:-/opt/homebrew/bin/brew}"
MBI_BREW_INSTALLER="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

ensure_homebrew() {
  if [ -x "$MBI_BREW_BIN" ]; then
    info "Homebrew už je nainstalovaný, aktualizuju ho…"
    "$MBI_BREW_BIN" update
  else
    info "Instaluju Homebrew a Command Line Tools od Applu. Může to trvat 10–20 minut…"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$MBI_BREW_INSTALLER")"
    [ -x "$MBI_BREW_BIN" ] || fail "Homebrew se nepodařilo nainstalovat. Zkontroluj připojení k internetu a spusť skript znovu."
  fi
  eval "$("$MBI_BREW_BIN" shellenv)"
  ok "Homebrew je připravený"
  note_installed "Homebrew"

  brew install git gh
  ok "git a gh jsou připravené"
}

# shellcheck shell=bash
# Everything from the Brewfile, plus upgrades of whatever Homebrew manages.

MBI_CASK_SKIP=""

# brewfile_casks <Brewfile> — cask names, one per line, in file order.
brewfile_casks() {
  sed -n 's/^cask "\([^"]*\)".*/\1/p' "$1"
}

# Installs casks one by one with --adopt, so apps installed by hand (e.g. a
# downloaded Chrome) come under Homebrew. A cask that cannot be adopted is
# skipped and left to update itself.
install_casks() {
  local brewfile="$1" managed cask
  managed="$(brew list --cask 2>/dev/null || true)"
  for cask in $(brewfile_casks "$brewfile"); do
    if printf '%s\n' "$managed" | grep -qx "$cask"; then
      continue
    fi
    info "Instaluju $cask…"
    if brew install --cask --adopt "$cask"; then
      ok "$cask nainstalováno"
    else
      warn "$cask se nepodařilo nainstalovat přes Homebrew, nechávám ho být."
      MBI_CASK_SKIP="${MBI_CASK_SKIP:+$MBI_CASK_SKIP }$cask"
      note_skipped "$cask (už je nainstalovaný mimo Homebrew nebo instalace selhala)"
    fi
  done
}

install_packages() {
  local brewfile="${1:-$MBI_ROOT/Brewfile}"
  install_casks "$brewfile"
  info "Instaluju nástroje z Brewfile…"
  HOMEBREW_BUNDLE_CASK_SKIP="$MBI_CASK_SKIP" brew bundle install --file="$brewfile"
  info "Aktualizuju všechno, co spravuje Homebrew…"
  brew upgrade
  ok "Nástroje a aplikace jsou nainstalované a aktuální"
  note_installed "Nástroje a aplikace z Brewfile (Ghostty, Zed, VS Code, Chrome, OrbStack, Flutter, …)"
}

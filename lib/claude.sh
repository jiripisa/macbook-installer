# shellcheck shell=bash
# Claude Code from the official native installer; it keeps itself updated.

MBI_CLAUDE_INSTALLER="https://claude.ai/install.sh"

install_claude() {
  if [ -x "$HOME/.local/bin/claude" ]; then
    ok "Claude Code už je nainstalovaný (aktualizuje se sám)"
    return 0
  fi
  info "Instaluju Claude Code…"
  curl -fsSL "$MBI_CLAUDE_INSTALLER" | bash
  ok "Claude Code nainstalovaný"
  note_installed "Claude Code"
  note_todo "Spusť v terminálu příkaz claude a přihlas se."
}

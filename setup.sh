#!/bin/bash
# Main installer flow. Normally started by install.sh; safe to run again,
# which is also how the machine gets updated.
set -Eeuo pipefail

MBI_ROOT="${MBI_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
for module in ui preflight homebrew github packages dotfiles runtimes claude xcode; do
  # shellcheck source=/dev/null
  source "$MBI_ROOT/lib/$module.sh"
done

intro() {
  printf '\n%sAhoj! Teď ti připravím Mac na programování.%s\n\n' "$C_BOLD" "$C_RESET"
  info "Nainstaluju terminál Ghostty, editory Zed a VS Code, Chrome, OrbStack,"
  info "Flutter, Claude Code, Javu, Node.js, Python, Go, Rust a spoustu nástrojů."
  info "Celé to zabere zhruba 30–60 minut podle rychlosti internetu."
  info ""
  info "Na začátku budu potřebovat tři věci:"
  info "  1. heslo, kterým se přihlašuješ do Macu,"
  info "  2. přihlášení na GitHub (otevře se prohlížeč),"
  info "  3. potvrzení jména a e-mailu pro git."
  info "Pak už všechno poběží samo."
}

outro() {
  printf '\n%s%sHotovo!%s\n' "$C_BOLD" "$C_GREEN" "$C_RESET"
  info "Teď zavři Terminál a otevři Ghostty (⌘ + mezerník, napiš „Ghostty“)."
  info "Až budeš chtít všechno aktualizovat, spusť stejný příkaz jako dnes."
  info "Záznam celého průběhu: $MBI_LOG"
}

on_exit() {
  local rc=$?
  stop_sudo_keepalive
  [ "$rc" -eq 0 ] || report_failure
  exit "$rc"
}

main() {
  local log_dir="$HOME/Library/Logs/macbook-installer"
  mkdir -p "$log_dir"
  MBI_LOG="$log_dir/install-$(date +%Y%m%d-%H%M%S).log"
  exec > >(tee -a "$MBI_LOG") 2>&1
  trap on_exit EXIT
  open_tty

  intro
  step "Kontrola Macu"
  preflight_checks
  step "Heslo k Macu"
  start_sudo_keepalive
  step "Homebrew"
  ensure_homebrew
  step "GitHub"
  setup_github
  info ""
  info "Od teď už nic zadávat nemusíš. Můžeš si dát pauzu."
  step "Aplikace a nástroje"
  install_packages
  step "Nastavení terminálu"
  install_dotfiles
  step "Programovací jazyky"
  install_runtimes
  step "Claude Code"
  install_claude
  step "Xcode"
  setup_xcode
  note_todo "Pro aplikace na iPhone spusť v Ghostty flutter doctor a zkontroluj, že je všechno zelené."

  step "Shrnutí"
  print_summary
  outro
}

main "$@"

# shellcheck shell=bash
# Language runtimes from ~/.config/mise/config.toml (written by install_dotfiles).

install_runtimes() {
  info "Instaluju Javu, Maven, Node, Python, Go a Rust. Poprvé to chvíli trvá…"
  (
    cd "$HOME" || exit 1
    export MISE_YES=1
    mise install
    mise upgrade
    mise prune --yes
  )
  ok "Runtimy jsou nainstalované a aktuální"
  note_installed "Java, Maven, Node.js, Python, Go a Rust (přes mise)"
}

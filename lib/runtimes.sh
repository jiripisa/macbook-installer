# shellcheck shell=bash
# Language runtimes from ~/.config/mise/conf.d/macbook-installer.toml (written
# by install_dotfiles) plus anything the son added with `mise use -g`.

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

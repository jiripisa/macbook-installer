# shellcheck shell=bash
# Checks that must pass before anything is installed, and the sudo session.

MBI_SUDO_PID=""

# is_admin_groups <space separated groups> — true when "admin" is one of them.
is_admin_groups() {
  case " $1 " in
    *" admin "*) return 0 ;;
    *) return 1 ;;
  esac
}

preflight_checks() {
  [ "$(uname -s)" = "Darwin" ] || fail "Tenhle skript je jen pro macOS."
  [ "$(uname -m)" = "arm64" ] ||
    fail "Tenhle skript počítá s Macem s čipem Apple Silicon (M1 a novější)."
  is_admin_groups "$(id -Gn)" ||
    fail "Tvůj uživatelský účet není administrátor. Popros tátu, ať ti v Nastavení systému → Uživatelé a skupiny povolí správu počítače, a pak skript spusť znovu."
  ok "Mac je připravený (Apple Silicon, účet administrátora)"
}

start_sudo_keepalive() {
  info "Teď zadej heslo, kterým se přihlašuješ do Macu."
  info "Při psaní se nic nezobrazuje, to je v pořádku. Pak zmáčkni Enter."
  sudo -p "    Heslo k Macu: " -v ||
    fail "Heslo se nepodařilo ověřit. Spusť skript znovu a zkus heslo zadat pečlivě."
  # Keep the sudo timestamp fresh while the (long) install runs.
  (
    while kill -0 "$$" 2>/dev/null; do
      sudo -n true
      sleep 50
    done
  ) >/dev/null 2>&1 &
  MBI_SUDO_PID=$!
  ok "Heslo ověřeno"
}

stop_sudo_keepalive() {
  [ -n "$MBI_SUDO_PID" ] || return 0
  kill "$MBI_SUDO_PID" 2>/dev/null || true
  MBI_SUDO_PID=""
}

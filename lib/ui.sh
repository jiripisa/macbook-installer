# shellcheck shell=bash
# Output helpers, prompts and the end-of-run summary.
# User-facing text is Czech on purpose: the installer is for a Czech beginner.

MBI_TTY="${MBI_TTY:-/dev/tty}"
MBI_STEP_NO=0
MBI_CURRENT_STEP=""
MBI_INSTALLED=()
MBI_SKIPPED=()
MBI_TODO=()

if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
  C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_RESET=$'\033[0m'
else
  C_BOLD="" C_BLUE="" C_GREEN="" C_YELLOW="" C_RED="" C_RESET=""
fi

step() {
  MBI_STEP_NO=$((MBI_STEP_NO + 1))
  MBI_CURRENT_STEP="$1"
  printf '\n%s%s==> %d. %s%s\n' "$C_BOLD" "$C_BLUE" "$MBI_STEP_NO" "$1" "$C_RESET"
}

info() { printf '    %s\n' "$1"; }
ok() { printf '    %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '    %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }

fail() {
  printf '\n%s%s✗ %s%s\n' "$C_BOLD" "$C_RED" "$1" "$C_RESET" >&2
  exit 1
}

have() { command -v "$1" >/dev/null 2>&1; }

# Opens the terminal once on fd 7, so answers are read in order even when
# ask runs inside $(...) subshells.
open_tty() {
  exec 7<"$MBI_TTY"
}

# ask <prompt> <default> — prints the answer on stdout. The prompt goes to
# stderr so callers can capture the answer with $(ask ...). Needs open_tty.
ask() {
  local prompt="$1" default="${2:-}" answer=""
  if [ -n "$default" ]; then
    printf '    %s%s [%s]:%s ' "$C_BOLD" "$prompt" "$default" "$C_RESET" >&2
  else
    printf '    %s%s:%s ' "$C_BOLD" "$prompt" "$C_RESET" >&2
  fi
  IFS= read -r answer <&7 || answer=""
  [ -n "$answer" ] || answer="$default"
  printf '%s\n' "$answer"
}

note_installed() { MBI_INSTALLED+=("$1"); }
note_skipped() { MBI_SKIPPED+=("$1"); }
note_todo() { MBI_TODO+=("$1"); }

print_list() {
  local title="$1" item
  shift
  [ "$#" -gt 0 ] || return 0
  printf '\n%s%s%s\n' "$C_BOLD" "$title" "$C_RESET"
  for item in "$@"; do
    printf '  • %s\n' "$item"
  done
}

print_summary() {
  print_list "Nainstalováno nebo aktualizováno:" ${MBI_INSTALLED[@]+"${MBI_INSTALLED[@]}"}
  print_list "Přeskočeno:" ${MBI_SKIPPED[@]+"${MBI_SKIPPED[@]}"}
  print_list "Zbývá udělat ručně:" ${MBI_TODO[@]+"${MBI_TODO[@]}"}
}

on_error() {
  printf '\n%s%s✗ Něco se pokazilo v kroku „%s“ (řádek %s).%s\n' \
    "$C_BOLD" "$C_RED" "${MBI_CURRENT_STEP:-start}" "$1" "$C_RESET" >&2
  printf '    Celý průběh je zapsaný v logu: %s\n' "${MBI_LOG:-(log není)}" >&2
  printf '    Zkus skript spustit znovu stejným příkazem. Když to nepomůže, ukaž log tátovi.\n' >&2
}

install_error_trap() {
  set -o errtrace
  trap 'on_error $LINENO' ERR
}

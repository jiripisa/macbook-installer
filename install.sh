#!/bin/bash
# Bootstrap for a fresh Mac. Run it with:
#   curl -fsSL https://raw.githubusercontent.com/jiripisa/macbook-installer/main/install.sh | bash
# Needs nothing beyond what ships with macOS: it downloads the repo as a
# tarball (git is not installed yet) and hands over to setup.sh.
set -euo pipefail

MBI_REPO_TARBALL="https://github.com/jiripisa/macbook-installer/archive/refs/heads/main.tar.gz"

# Everything lives in main so a partially downloaded script never runs.
main() {
  local script_dir="" root
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi

  if [ -n "$script_dir" ] && [ -f "$script_dir/setup.sh" ]; then
    root="$script_dir"
  else
    root="$(mktemp -d)/macbook-installer"
    mkdir -p "$root"
    echo "Stahuju instalační skript…"
    curl -fsSL "$MBI_REPO_TARBALL" | tar -xz --strip-components 1 -C "$root"
  fi

  export MBI_ROOT="$root"
  # Piped from curl, stdin is this script; prompts must come from the terminal.
  exec /bin/bash "$root/setup.sh" < "${MBI_TTY:-/dev/tty}"
}

main "$@"

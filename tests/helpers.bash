# shellcheck shell=bash
# Shared test setup: every test runs against a throwaway HOME with stub
# commands first on PATH, so nothing touches the real machine.

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup_env() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export MBI_ROOT="$REPO_ROOT"
  export MBI_TTY="$TEST_HOME/tty"
  export MBI_APPS_DIR="$TEST_HOME/Applications"
  export MBI_BREW_BIN="$REPO_ROOT/tests/stubs/brew"
  export STUB_LOG="$TEST_HOME/calls.log"
  export STUB_STATE="$TEST_HOME/stub-state"
  export NO_COLOR=1
  export PATH="$REPO_ROOT/tests/stubs:$PATH"
  mkdir -p "$MBI_APPS_DIR" "$STUB_STATE"
  : > "$MBI_TTY"
  : > "$STUB_LOG"
}

teardown_env() {
  rm -rf "$TEST_HOME"
}

# Lines typed by the "user", one per prompt.
type_answers() {
  printf '%s\n' "$@" > "$MBI_TTY"
}

assert_called() {
  grep -qF -- "$1" "$STUB_LOG" || {
    echo "expected call: $1"
    echo "--- calls ---"
    cat "$STUB_LOG"
    return 1
  }
}

refute_called() {
  if grep -qF -- "$1" "$STUB_LOG"; then
    echo "unexpected call: $1"
    echo "--- calls ---"
    cat "$STUB_LOG"
    return 1
  fi
}

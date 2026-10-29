#!/usr/bin/env bats
# End-to-end runs of the whole installer against stubs and a temporary HOME.

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  type_answers "" ""
}

teardown() { teardown_env; }

@test "setup.sh completes, logs the run and prints the summary" {
  run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hotovo"* ]]
  [[ "$output" == *"Zbývá udělat ručně"* ]]
  log="$(find "$HOME/Library/Logs/macbook-installer" -name 'install-*.log')"
  [ -n "$log" ]
  grep -q "Homebrew" "$log"
}

@test "steps run in the agreed order" {
  run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -eq 0 ]
  order="$(grep -oE '^(sudo -p|brew update|gh auth|brew bundle|mise install|curl -fsSL https://claude)' "$STUB_LOG" | uniq | tr '\n' '|')"
  [ "$order" = "sudo -p|brew update|gh auth|brew bundle|mise install|curl -fsSL https://claude|" ]
}

@test "a second run creates no backups and still succeeds" {
  run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -eq 0 ]
  type_answers "" ""
  run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -eq 0 ]
  [ "$(find "$HOME" -name '*.backup-*' | wc -l | tr -d ' ')" = "0" ]
}

@test "install.sh run from a checkout uses the local files" {
  run /bin/bash "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hotovo"* ]]
  refute_called "tar.gz"
}

@test "install.sh piped into bash downloads the repo and runs it" {
  export STUB_CURL_TARBALL="$TEST_HOME/repo.tar.gz"
  tar -czf "$STUB_CURL_TARBALL" -s ',^\.,macbook-installer-main,' \
    --exclude .git --exclude .superpowers -C "$REPO_ROOT" .
  unset MBI_ROOT
  cd "$TEST_HOME"
  run /bin/bash -c "cat '$REPO_ROOT/install.sh' | /bin/bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hotovo"* ]]
  assert_called "curl -fsSL https://github.com/jiripisa/macbook-installer/archive/refs/heads/main.tar.gz"
}

@test "a non-admin user is stopped before the password prompt" {
  STUB_GROUPS="staff everyone" run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"administrátor"* ]]
  refute_called "sudo"
}

@test "a failing step reports itself and the log path once" {
  STUB_MISE_EXIT=1 run /bin/bash "$REPO_ROOT/setup.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Programovací jazyky"* ]]
  [[ "$output" == *"Library/Logs/macbook-installer/install-"* ]]
  [ "$(grep -c "Něco se pokazilo" <<< "$output")" = "1" ]
}

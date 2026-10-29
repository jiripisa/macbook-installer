#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  # shellcheck source=../lib/ui.sh
  source "$REPO_ROOT/lib/ui.sh"
}

teardown() { teardown_env; }

@test "ask returns the typed answer" {
  type_answers "Petr"
  run --separate-stderr ask "Jméno" "Jan"
  [ "$status" -eq 0 ]
  [ "$output" = "Petr" ]
}

@test "ask returns the default on an empty line" {
  type_answers ""
  run --separate-stderr ask "Jméno" "Jan"
  [ "$output" = "Jan" ]
}

@test "ask prints the prompt with the default to stderr, not stdout" {
  type_answers ""
  run --separate-stderr ask "Jméno" "Jan"
  [[ "$stderr" == *"Jméno [Jan]"* ]]
  [ "$output" = "Jan" ]
}

@test "consecutive asks read consecutive lines" {
  type_answers "první" "druhá"
  a="$(ask "A" "x" 2>/dev/null)"
  b="$(ask "B" "y" 2>/dev/null)"
  [ "$a" = "první" ]
  [ "$b" = "druhá" ]
}

@test "print_summary lists items from all three lists" {
  note_installed "git"
  note_skipped "Google Chrome"
  note_todo "Nainstaluj Xcode"
  run print_summary
  [[ "$output" == *"git"* ]]
  [[ "$output" == *"Google Chrome"* ]]
  [[ "$output" == *"Nainstaluj Xcode"* ]]
}

@test "print_summary works with empty lists under set -u" {
  run bash -c 'set -u; source "$1"; print_summary' _ "$REPO_ROOT/lib/ui.sh"
  [ "$status" -eq 0 ]
}

@test "fail prints the message and exits non-zero" {
  run bash -c 'source "$1"; fail "Tohle se nepovedlo"; echo after' _ "$REPO_ROOT/lib/ui.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Tohle se nepovedlo"* ]]
  [[ "$output" != *"after"* ]]
}

#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  source "$REPO_ROOT/lib/preflight.sh"
}

teardown() {
  stop_sudo_keepalive
  teardown_env
}

@test "is_admin_groups accepts a group list containing admin" {
  run is_admin_groups "staff everyone admin"
  [ "$status" -eq 0 ]
}

@test "is_admin_groups rejects a list without admin" {
  run is_admin_groups "staff everyone"
  [ "$status" -eq 1 ]
}

@test "is_admin_groups needs an exact word match" {
  run is_admin_groups "staff administrators"
  [ "$status" -eq 1 ]
}

@test "preflight_checks passes on an Apple Silicon Mac with an admin user" {
  run preflight_checks
  [ "$status" -eq 0 ]
}

@test "preflight_checks fails in Czech on an Intel Mac" {
  STUB_ARCH=x86_64 run preflight_checks
  [ "$status" -eq 1 ]
  [[ "$output" == *"Apple Silicon"* ]]
}

@test "preflight_checks fails in Czech for a non-admin user" {
  STUB_GROUPS="staff everyone" run preflight_checks
  [ "$status" -eq 1 ]
  [[ "$output" == *"administrátor"* ]]
}

@test "start_sudo_keepalive asks for the password via sudo -v" {
  start_sudo_keepalive
  assert_called "sudo -p"
  assert_called " -v"
}

@test "start_sudo_keepalive fails in Czech when the password is wrong" {
  STUB_SUDO_EXIT=1 run start_sudo_keepalive
  [ "$status" -eq 1 ]
  [[ "$output" == *"heslo"* ]]
}

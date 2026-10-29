#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  source "$REPO_ROOT/lib/runtimes.sh"
  source "$REPO_ROOT/lib/claude.sh"
  source "$REPO_ROOT/lib/xcode.sh"
}

teardown() { teardown_env; }

@test "install_runtimes installs, upgrades and prunes from HOME" {
  install_runtimes
  assert_called "mise install (cwd=$HOME)"
  assert_called "mise upgrade"
  assert_called "mise prune --yes"
}

@test "install_claude runs the official installer when claude is missing" {
  install_claude
  assert_called "curl -fsSL https://claude.ai/install.sh"
}

@test "install_claude skips an existing installation" {
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/sh\n' > "$HOME/.local/bin/claude"
  chmod +x "$HOME/.local/bin/claude"
  install_claude
  refute_called "curl"
}

@test "setup_xcode without Xcode leaves an App Store todo and touches nothing" {
  setup_xcode
  [[ "${MBI_TODO[*]}" == *"App Store"* ]]
  refute_called "sudo"
  refute_called "xcodebuild"
}

@test "setup_xcode selects Xcode, accepts the license and runs first launch" {
  mkdir -p "$MBI_APPS_DIR/Xcode.app"
  setup_xcode
  assert_called "sudo xcode-select -s $MBI_APPS_DIR/Xcode.app/Contents/Developer"
  assert_called "sudo xcodebuild -license accept"
  assert_called "sudo xcodebuild -runFirstLaunch"
}

@test "setup_xcode does not re-select Xcode when it is already selected" {
  mkdir -p "$MBI_APPS_DIR/Xcode.app"
  STUB_XCODE_PATH="$MBI_APPS_DIR/Xcode.app/Contents/Developer" setup_xcode
  refute_called "sudo xcode-select -s"
}

@test "setup_xcode downloads the iOS platform when no iOS simulator exists" {
  mkdir -p "$MBI_APPS_DIR/Xcode.app"
  setup_xcode
  assert_called "xcodebuild -downloadPlatform iOS"
}

@test "setup_xcode skips the iOS download when a simulator runtime exists" {
  mkdir -p "$MBI_APPS_DIR/Xcode.app"
  STUB_SIM_RUNTIMES="iOS 26.0 (26.0 - 23A339) - com.apple.CoreSimulator.SimRuntime.iOS-26-0" setup_xcode
  refute_called "xcodebuild -downloadPlatform"
}

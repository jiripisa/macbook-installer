#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  source "$REPO_ROOT/lib/dotfiles.sh"
  source "$REPO_ROOT/lib/github.sh"
  type_answers "" ""
}

teardown() { teardown_env; }

@test "noreply_email builds the GitHub noreply address" {
  [ "$(noreply_email 123 kid)" = "123+kid@users.noreply.github.com" ]
}

@test "key_registered finds the key body in the gh ssh-key list output" {
  printf 'ssh-ed25519 AAAAmine kid@mac\n' > "$TEST_HOME/k.pub"
  run key_registered "$TEST_HOME/k.pub" "MacBook  ssh-ed25519 AAAAmine  2026-10-29  123  authentication"
  [ "$status" -eq 0 ]
  run key_registered "$TEST_HOME/k.pub" "Other  ssh-ed25519 AAAAother  2026-10-29  124  authentication"
  [ "$status" -eq 1 ]
}

@test "setup_github logs in via the browser with the SSH key scope when logged out" {
  setup_github
  assert_called "gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key"
}

@test "setup_github does not log in again when already logged in" {
  touch "$STUB_STATE/gh_logged_in"
  setup_github
  refute_called "gh auth login"
}

@test "setup_github refreshes the token when it cannot list SSH keys" {
  touch "$STUB_STATE/gh_logged_in"
  STUB_GH_NO_KEY_SCOPE=1 setup_github
  assert_called "gh auth refresh --hostname github.com --scopes admin:public_key"
}

@test "setup_github sets SSH as the git protocol" {
  setup_github
  assert_called "gh config set git_protocol ssh --host github.com"
}

@test "setup_github creates an ed25519 key without a passphrase and uploads it" {
  setup_github
  [ -f "$HOME/.ssh/id_ed25519" ]
  ssh-keygen -y -P "" -f "$HOME/.ssh/id_ed25519" >/dev/null
  assert_called "gh ssh-key add $HOME/.ssh/id_ed25519.pub --title"
}

@test "setup_github keeps an existing key and does not upload it twice" {
  setup_github
  : > "$STUB_LOG"
  key_before="$(cat "$HOME/.ssh/id_ed25519.pub")"
  type_answers "" ""
  setup_github
  [ "$(cat "$HOME/.ssh/id_ed25519.pub")" = "$key_before" ]
  refute_called "gh ssh-key add"
}

@test "setup_github trusts GitHub host keys from the API, once" {
  setup_github
  type_answers "" ""
  setup_github
  [ "$(grep -c '^github.com ' "$HOME/.ssh/known_hosts")" = "2" ]
}

@test "git identity defaults come from the GitHub account" {
  setup_github
  [ "$(git config --global user.name)" = "Petr Novák" ]
  [ "$(git config --global user.email)" = "petr@example.com" ]
}

@test "a private GitHub email defaults to the noreply address" {
  STUB_GH_EMAIL="" setup_github
  [ "$(git config --global user.email)" = "123+kid@users.noreply.github.com" ]
}

@test "an account without a name defaults to the login" {
  STUB_GH_NAME="" setup_github
  [ "$(git config --global user.name)" = "kid" ]
}

@test "typed answers override the defaults" {
  type_answers "Péťa" "peta@example.com"
  setup_github
  [ "$(git config --global user.name)" = "Péťa" ]
  [ "$(git config --global user.email)" = "peta@example.com" ]
}

@test "an existing git identity is offered as the default on re-run" {
  git config --global user.name "Vlastní Jméno"
  git config --global user.email "vlastni@example.com"
  setup_github
  [ "$(git config --global user.name)" = "Vlastní Jméno" ]
  [ "$(git config --global user.email)" = "vlastni@example.com" ]
}

@test "gh login and refresh get a terminal so the browser opens" {
  STUB_GH_NO_KEY_SCOPE=1 setup_github
  assert_called "gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key [tty]"
  assert_called "gh auth refresh --hostname github.com --scopes admin:public_key [tty]"
}

@test "keys typed while waiting are discarded before the git identity questions" {
  drain_calls=0
  drain_tty() { drain_calls=$((drain_calls + 1)); }
  setup_github
  [ "$drain_calls" -ge 1 ]
}

@test "the English signing-key warning from gh is not shown" {
  run setup_github
  [[ "$output" != *"warning: HTTP 404"* ]]
}

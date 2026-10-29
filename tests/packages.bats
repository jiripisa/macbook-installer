#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  source "$REPO_ROOT/lib/homebrew.sh"
  source "$REPO_ROOT/lib/packages.sh"
  BREWFILE="$TEST_HOME/Brewfile"
  printf '%s\n' 'brew "git"' 'cask "ghostty"' 'cask "google-chrome"' > "$BREWFILE"
}

teardown() { teardown_env; }

@test "brewfile_casks lists cask names in order" {
  run brewfile_casks "$BREWFILE"
  [ "$output" = "$(printf 'ghostty\ngoogle-chrome')" ]
}

@test "repo Brewfile contains every package from the spec" {
  for f in git gh micro mise starship zsh-autosuggestions zsh-syntax-highlighting \
           fzf direnv eza bat zoxide git-delta lazygit glow jq ripgrep fd uv \
           xcodegen xcbeautify swiftformat swiftlint cocoapods; do
    grep -qx "brew \"$f\"" "$REPO_ROOT/Brewfile" || { echo "missing formula $f"; return 1; }
  done
  run brewfile_casks "$REPO_ROOT/Brewfile"
  for c in ghostty zed visual-studio-code google-chrome orbstack \
           font-jetbrains-mono-nerd-font flutter; do
    [[ "$output" == *"$c"* ]] || { echo "missing cask $c"; return 1; }
  done
}

@test "install_casks skips casks Homebrew already manages" {
  printf 'ghostty\ngoogle-chrome\n' > "$STUB_STATE/casks"
  install_casks "$BREWFILE"
  refute_called "brew install --cask"
}

@test "install_casks installs missing casks with --adopt" {
  install_casks "$BREWFILE"
  assert_called "brew install --cask --adopt ghostty"
  assert_called "brew install --cask --adopt google-chrome"
}

@test "install_casks skips a cask whose adoption fails and keeps going" {
  STUB_ADOPT_FAIL="google-chrome" install_casks "$BREWFILE"
  [ "$MBI_CASK_SKIP" = "google-chrome" ]
  [[ " ${MBI_SKIPPED[*]} " == *"google-chrome"* ]]
  assert_called "brew install --cask --adopt ghostty"
}

@test "install_packages passes skipped casks to brew bundle, then upgrades all" {
  STUB_ADOPT_FAIL="google-chrome" install_packages "$BREWFILE"
  assert_called "brew bundle install --file=$BREWFILE [CASK_SKIP=google-chrome]"
  [ "$(tail -1 "$STUB_LOG" | cut -d' ' -f1-2)" = "brew upgrade" ]
}

@test "ensure_homebrew updates an existing Homebrew and installs git and gh" {
  ensure_homebrew
  refute_called "curl"
  assert_called "brew update"
  assert_called "brew install git gh"
}

@test "ensure_homebrew runs the official installer when Homebrew is missing" {
  export MBI_BREW_BIN="$TEST_HOME/homebrew/bin/brew"
  export STUB_CURL_BODY="mkdir -p '$TEST_HOME/homebrew/bin' && ln -s '$REPO_ROOT/tests/stubs/brew' '$MBI_BREW_BIN'"
  ensure_homebrew
  assert_called "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  assert_called "brew install git gh"
}

@test "ensure_homebrew fails in Czech when the installer does not produce brew" {
  export MBI_BREW_BIN="$TEST_HOME/nowhere/brew"
  run ensure_homebrew
  [ "$status" -eq 1 ]
  [[ "$output" == *"Homebrew"* ]]
}

#!/usr/bin/env bats

load helpers

setup() {
  setup_env
  source "$REPO_ROOT/lib/ui.sh"
  source "$REPO_ROOT/lib/dotfiles.sh"
  SRC="$TEST_HOME/src"
  printf 'new content\n' > "$SRC"
}

teardown() { teardown_env; }

backups_of() {
  find "$(dirname "$1")" -maxdepth 1 -name "$(basename "$1").backup-*" | wc -l | tr -d ' '
}

@test "sync_managed_file creates a missing file without a backup" {
  sync_managed_file "$SRC" "$HOME/.zshrc"
  [ "$(cat "$HOME/.zshrc")" = "new content" ]
  [ "$(backups_of "$HOME/.zshrc")" = "0" ]
}

@test "sync_managed_file reports paths relative to ~" {
  run sync_managed_file "$SRC" "$HOME/.zshrc"
  [[ "$output" == *"~/.zshrc"* ]]
  [[ "$output" != *"$HOME"* ]]
}

@test "sync_managed_file creates missing parent directories" {
  sync_managed_file "$SRC" "$HOME/.config/ghostty/config"
  [ -f "$HOME/.config/ghostty/config" ]
}

@test "sync_managed_file leaves an identical file alone" {
  cp "$SRC" "$HOME/.zshrc"
  sync_managed_file "$SRC" "$HOME/.zshrc"
  [ "$(backups_of "$HOME/.zshrc")" = "0" ]
}

@test "sync_managed_file backs up a different file and replaces it" {
  printf 'old content\n' > "$HOME/.zshrc"
  sync_managed_file "$SRC" "$HOME/.zshrc"
  [ "$(cat "$HOME/.zshrc")" = "new content" ]
  [ "$(backups_of "$HOME/.zshrc")" = "1" ]
  backup="$(find "$HOME" -maxdepth 1 -name '.zshrc.backup-*')"
  [ "$(cat "$backup")" = "old content" ]
  [[ "$backup" =~ \.zshrc\.backup-[0-9]{8}-[0-9]{6}$ ]]
}

@test "ensure_zshrc_local creates the file when missing" {
  ensure_zshrc_local
  [ -f "$HOME/.zshrc.local" ]
}

@test "ensure_zshrc_local never overwrites an existing file" {
  printf 'alias hi="echo ahoj"\n' > "$HOME/.zshrc.local"
  ensure_zshrc_local
  [ "$(cat "$HOME/.zshrc.local")" = 'alias hi="echo ahoj"' ]
}

@test "apply_git_config sets identity and defaults and keeps other keys" {
  git config --global alias.st status
  apply_git_config "Petr Novák" "petr@example.com"
  [ "$(git config --global user.name)" = "Petr Novák" ]
  [ "$(git config --global user.email)" = "petr@example.com" ]
  [ "$(git config --global core.editor)" = "micro" ]
  [ "$(git config --global core.pager)" = "delta" ]
  [ "$(git config --global delta.navigate)" = "true" ]
  [ "$(git config --global delta.side-by-side)" = "true" ]
  [ "$(git config --global init.defaultBranch)" = "main" ]
  [ "$(git config --global core.excludesFile)" = "~/.gitignore_global" ]
  [ "$(git config --global alias.st)" = "status" ]
}

@test "install_dotfiles puts every managed file in place" {
  install_dotfiles
  for f in .zprofile .zshrc .config/starship.toml .config/ghostty/config \
           .gitignore_global .config/mise/config.toml .zshrc.local; do
    [ -f "$HOME/$f" ] || { echo "missing $f"; return 1; }
  done
}

@test "install_dotfiles run twice creates no backups" {
  install_dotfiles
  install_dotfiles
  [ "$(find "$HOME" -name '*.backup-*' | wc -l | tr -d ' ')" = "0" ]
}

@test "managed zshrc has no aliases for standard commands and no atuin" {
  ! grep -Eq "alias (ls|cat|cd)=" "$REPO_ROOT/config/zshrc"
  ! grep -q atuin "$REPO_ROOT/config/zshrc"
}

@test "managed zshrc sources ~/.zshrc.local last" {
  [[ "$(grep -v '^\s*$' "$REPO_ROOT/config/zshrc" | tail -1)" == *".zshrc.local"* ]]
}

@test "zsh config files have valid syntax" {
  zsh -n "$REPO_ROOT/config/zshrc"
  zsh -n "$REPO_ROOT/config/zprofile"
  zsh -n "$REPO_ROOT/config/zshrc.local"
}

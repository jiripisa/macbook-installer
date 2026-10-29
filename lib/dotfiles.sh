# shellcheck shell=bash
# Managed config files. The installer owns these and keeps them in sync with
# the repo; the son's own settings live in ~/.zshrc.local and
# ~/.config/mise/config.toml, which are never overwritten.

# pretty_path <path> — $HOME shown as ~ (a literal ~ in ${var/…/~} would be
# tilde-expanded back to $HOME by bash 3.2).
pretty_path() {
  local tilde="~"
  printf '%s\n' "${1/#$HOME/$tilde}"
}

# sync_managed_file <src> <dest> — copy src to dest; a different existing dest
# is backed up as <dest>.backup-<YYYYmmdd-HHMMSS> first.
sync_managed_file() {
  local src="$1" dest="$2" backup
  mkdir -p "$(dirname "$dest")"
  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
    ok "Vytvořeno: $(pretty_path "$dest")"
  elif cmp -s "$src" "$dest"; then
    ok "Beze změny: $(pretty_path "$dest")"
  else
    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    cp "$src" "$dest"
    warn "Aktualizováno: $(pretty_path "$dest") (původní verze je v $(pretty_path "$backup"))"
  fi
}

ensure_zshrc_local() {
  [ -e "$HOME/.zshrc.local" ] && return 0
  cp "$MBI_ROOT/config/zshrc.local" "$HOME/.zshrc.local"
  ok "Vytvořeno: ~/.zshrc.local (sem si můžeš psát vlastní nastavení)"
}

# apply_git_config <name> <email> — sets single values, so anything else in
# ~/.gitconfig stays untouched.
apply_git_config() {
  git config --global user.name "$1"
  git config --global user.email "$2"
  git config --global core.editor micro
  git config --global core.pager delta
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global init.defaultBranch main
  # shellcheck disable=SC2088 # git expands ~ itself
  git config --global core.excludesFile "~/.gitignore_global"
}

install_dotfiles() {
  local c="$MBI_ROOT/config"
  sync_managed_file "$c/zprofile" "$HOME/.zprofile"
  sync_managed_file "$c/zshrc" "$HOME/.zshrc"
  sync_managed_file "$c/starship.toml" "$HOME/.config/starship.toml"
  sync_managed_file "$c/ghostty/config" "$HOME/.config/ghostty/config"
  sync_managed_file "$c/gitignore_global" "$HOME/.gitignore_global"
  # conf.d keeps ~/.config/mise/config.toml free for the son's own `mise use -g`
  sync_managed_file "$c/mise/macbook-installer.toml" "$HOME/.config/mise/conf.d/macbook-installer.toml"
  ensure_zshrc_local
}

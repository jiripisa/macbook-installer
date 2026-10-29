# shellcheck shell=bash
# GitHub login, SSH key and git identity.

# noreply_email <id> <login>
noreply_email() {
  printf '%s+%s@users.noreply.github.com\n' "$1" "$2"
}

# key_registered <pubkey file> <output of gh ssh-key list>
key_registered() {
  local body
  body="$(awk '{print $2}' "$1")"
  printf '%s\n' "$2" | grep -qF -- "$body"
}

github_login() {
  if gh auth status >/dev/null 2>&1; then
    ok "Na GitHubu už jsi přihlášený"
  else
    info "Teď se přihlásíš na GitHub."
    info "Skript ti ukáže jednorázový kód. Zmáčkni Enter, v prohlížeči se přihlas a kód opiš."
    gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key
  fi
  if ! gh ssh-key list >/dev/null 2>&1; then
    info "GitHub ještě potřebuje povolit správu SSH klíčů. Postup je stejný jako u přihlášení."
    gh auth refresh --hostname github.com --scopes admin:public_key
  fi
  gh config set git_protocol ssh --host github.com
  ok "GitHub je propojený"
}

setup_git_identity() {
  local login id name email default_name default_email
  login="$(gh api user --jq .login)"
  id="$(gh api user --jq .id)"
  name="$(gh api user --jq .name)"
  email="$(gh api user --jq .email)"

  default_name="$(git config --global user.name || true)"
  [ -n "$default_name" ] || default_name="${name:-$login}"
  default_email="$(git config --global user.email || true)"
  [ -n "$default_email" ] || default_email="${email:-$(noreply_email "$id" "$login")}"

  info "Git potřebuje jméno a e-mail, které se uloží ke každé tvé změně (commitu)."
  info "Navržené hodnoty potvrdíš Enterem, nebo napiš jiné."
  name="$(ask "Jméno" "$default_name")"
  email="$(ask "E-mail" "$default_email")"
  apply_git_config "$name" "$email"
  ok "Git nastavený: $name <$email>"
}

ensure_ssh_key() {
  local key="$HOME/.ssh/id_ed25519"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  if [ ! -f "$key" ]; then
    ssh-keygen -q -t ed25519 -N "" -C "$(git config --global user.email)" -f "$key"
    ok "Vytvořen SSH klíč $key"
  fi
  if key_registered "$key.pub" "$(gh ssh-key list)"; then
    ok "SSH klíč už je na GitHubu"
  else
    gh ssh-key add "$key.pub" --title "MacBook ($(hostname -s))"
    ok "SSH klíč přidán na GitHub"
    note_installed "SSH klíč na GitHubu"
  fi
}

# Trust GitHub's host keys as published by its API (over HTTPS), so the first
# git clone does not stop with an "are you sure" question.
ensure_github_known_hosts() {
  local known="$HOME/.ssh/known_hosts"
  touch "$known"
  chmod 600 "$known"
  grep -q '^github.com ' "$known" && return 0
  gh api meta --jq '.ssh_keys[]' | sed 's/^/github.com /' >> "$known"
}

setup_github() {
  github_login
  setup_git_identity
  ensure_ssh_key
  ensure_github_known_hosts
}

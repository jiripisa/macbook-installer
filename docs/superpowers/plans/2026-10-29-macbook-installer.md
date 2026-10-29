# MacBook Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `curl … | bash` installer that turns a fresh MacBook Air into a configured dev machine for a beginner, safe to re-run as an updater.

**Architecture:** `install.sh` is a tiny bootstrap (bash 3.2, no git needed) that downloads the repo tarball and execs `setup.sh` with stdin from the terminal. `setup.sh` sources focused `lib/*.sh` modules, one per step, and runs them in the agreed order. Every external path/command the modules touch is overridable via `MBI_*` env vars, so the whole flow is testable with stub commands and a temporary `HOME` — never against the real machine.

**Tech Stack:** bash 3.2 (macOS `/bin/bash`), Homebrew + Brewfile, mise, gh, bats-core + shellcheck for tests, GitHub Actions (macOS runner) for CI.

**Spec:** `docs/superpowers/specs/2026-10-29-macbook-installer-design.md`

## Global Constraints

- Bash 3.2 compatible: no associative arrays, no `${var,,}`, no `mapfile`; empty arrays expanded as `${arr[@]+"${arr[@]}"}` under `set -u`.
- All user-facing text (script output, prompts, README) in **Czech**; code, identifiers, comments, commit messages in English.
- Prompts read from `${MBI_TTY:-/dev/tty}`, never from stdin.
- No `ls`/`cat`/`cd` aliases, no atuin, no Finder/macOS system tweaks.
- Never run `setup.sh` for real on the developer's machine; tests always set `HOME` to a temp dir and put stubs first on `PATH`.
- Commits without any AI attribution trailers.
- Repo: public `jiripisa/macbook-installer`, branch `main`.

## Review Focus

1. Re-run on an already configured Mac → no new backups, no prompts except git identity confirmation, exit 0.
2. Chrome installed manually and `--adopt` fails (version mismatch) → warning, Chrome skipped from `brew bundle`, run continues.
3. GitHub account with private email → noreply address `<id>+<login>@users.noreply.github.com` offered as default.
4. User is not admin → stops before asking for password, Czech message explaining the father must make the account admin.
5. Any step fails mid-run → ERR trap prints the failing step and the log path in Czech, exit non-zero.

---

## File Structure

```
install.sh                 bootstrap: locate or download repo, exec setup.sh
setup.sh                   orchestrator: sources lib/*.sh, runs steps, summary
lib/ui.sh                  colors, step/info/ok/warn/fail, ask, run logging, summary lists, ERR trap
lib/preflight.sh           macOS/arch check, admin check, sudo keepalive
lib/homebrew.sh            install/update Homebrew, shellenv, base formulae (git, gh)
lib/github.sh              gh login, SSH key, git identity
lib/packages.sh            cask adoption, brew bundle, brew upgrade
lib/runtimes.sh            mise install/upgrade/prune
lib/claude.sh              Claude Code native installer
lib/dotfiles.sh            managed file sync, git config values, ~/.zshrc.local
lib/xcode.sh               Xcode detection and setup, iOS platform
Brewfile
config/zprofile  config/zshrc  config/zshrc.local  config/gitignore_global
config/starship.toml  config/ghostty/config  config/mise/config.toml
tests/helpers.bash         temp HOME, stub PATH, call log
tests/stubs/*              fake brew, gh, mise, sudo, curl, id, xcode-select, xcodebuild, ...
tests/*.bats
Makefile                   `make test` = shellcheck + bats
README.md                  Czech guide
.github/workflows/test.yml
```

## Shared interfaces (lib/ui.sh, used by every task)

- `step "<title>"` – numbered section header.
- `info|ok|warn "<msg>"`, `fail "<msg>"` (prints and `exit 1`).
- `ask "<prompt>" "<default>"` → echoes answer (default on empty input), reads `$MBI_TTY`.
- `note_installed|note_skipped|note_todo "<text>"` – append to summary lists; `print_summary`.
- `MBI_ROOT` (repo dir), `MBI_LOG` (log file, default `$HOME/Library/Logs/macbook-installer/install-<timestamp>.log`).
- Overridable paths: `MBI_BREW_BIN` (default `/opt/homebrew/bin/brew`), `MBI_APPS_DIR` (default `/Applications`), `MBI_TTY`.

---

### Task 1: Skeleton, test harness, ui.sh

**Files:** Create `lib/ui.sh`, `tests/helpers.bash`, `tests/ui.bats`, `Makefile`, `.gitignore`.

- [ ] Install dev tools on the developer machine: `brew install shellcheck bats-core`.
- [ ] `git init -b main`.
- [ ] Write `tests/ui.bats`: `ask` returns typed answer; returns default on empty line; `print_summary` lists items from all three lists and prints nothing for empty lists under `set -u`.
- [ ] Run `bats tests/ui.bats` → FAIL.
- [ ] Implement `lib/ui.sh` (interfaces above).
- [ ] `make test` → shellcheck clean, bats PASS. Commit `feat: add ui helpers and test harness`.

### Task 2: Preflight

**Files:** Create `lib/preflight.sh`, `tests/preflight.bats`.

- [ ] Tests: `is_admin_groups "staff everyone admin"` → 0; `"staff everyone"` → 1; `"administrators"` → 1 (exact word match); `preflight_checks` with stubbed `uname -m` = `x86_64` fails with Czech message.
- [ ] Implement `is_admin_groups <groups>`, `preflight_checks` (Darwin + arm64 + admin via `id -Gn`), `start_sudo_keepalive` (`sudo -p "…" -v` then background `sudo -n true` loop every 50 s, killed on EXIT).
- [ ] `make test` PASS. Commit.

### Task 3: Dotfiles and config content

**Files:** Create `lib/dotfiles.sh`, `config/*` (all files listed in File Structure), `tests/dotfiles.bats`.

- [ ] Tests for `sync_managed_file <src> <dest>`: dest missing → created, no backup; identical → untouched, no backup; different → `<dest>.backup-<YYYYmmdd-HHMMSS>` holds old content and dest equals src. `ensure_zshrc_local`: created from template when missing, never overwritten when present. `apply_git_config "<name>" "<email>"`: values set in `$HOME/.gitconfig`, a pre-existing unrelated key (`alias.st`) survives.
- [ ] Implement functions; `install_dotfiles` syncs: `config/zprofile→~/.zprofile`, `config/zshrc→~/.zshrc`, `config/starship.toml→~/.config/starship.toml`, `config/ghostty/config→~/.config/ghostty/config`, `config/gitignore_global→~/.gitignore_global`, `config/mise/config.toml→~/.config/mise/config.toml`.
- [ ] Config content per spec "Configuration content": zshrc (starship, autosuggestions, syntax-highlighting, mise, fzf, direnv, `~/.local/bin`, prefix history search, compinit, source `~/.zshrc.local` last); starship.toml copied from `~/.config/starship.toml`; ghostty `font-family = JetBrainsMono Nerd Font` + `window-inherit-working-directory = false`; gitignore `.DS_Store`, `.envrc`, `**/.claude/settings.local.json`; mise `java="temurin-25" maven="latest" node="lts" python="latest" go="latest" rust="latest"`; git values `core.editor=micro core.pager=delta delta.navigate=true delta.side-by-side=true init.defaultBranch=main core.excludesFile=~/.gitignore_global`.
- [ ] `zsh -n config/zshrc config/zprofile` clean; `make test` PASS. Commit.

### Task 4: Homebrew and packages

**Files:** Create `lib/homebrew.sh`, `lib/packages.sh`, `Brewfile`, `tests/packages.bats`, stubs `tests/stubs/brew`, `tests/stubs/curl`.

- [ ] Brewfile: formulae and casks exactly per spec "Package set" (incl. `cocoapods`, cask `flutter`).
- [ ] Tests: `brewfile_casks <file>` lists cask names in order; `install_casks` with stub brew: cask already in `brew list --cask` → no install call; not installed → `brew install --cask --adopt <c>`; adopt failure → cask in `MBI_CASK_SKIP`, warning, return 0; `install_packages` calls `brew bundle install --file=…` with `HOMEBREW_BUNDLE_CASK_SKIP` set to the skipped casks, then `brew upgrade`.
- [ ] Implement `ensure_homebrew` (installs via official script with `NONINTERACTIVE=1` when `$MBI_BREW_BIN` missing, else `brew update`; then `eval "$(brew shellenv)"`; then `brew install git gh` / upgrade), `brewfile_casks`, `install_casks`, `install_packages`.
- [ ] `make test` PASS. Commit.

### Task 5: GitHub

**Files:** Create `lib/github.sh`, `tests/github.bats`, stub `tests/stubs/gh`.

- [ ] Tests: `noreply_email 123 kid` → `123+kid@users.noreply.github.com`; `key_registered <pubfile> <listing>` true when key body appears in `gh ssh-key list` output; `setup_github` with stub gh logged in + key present → no `ssh-key add`; key missing → `ssh-keygen` creates `~/.ssh/id_ed25519` with empty passphrase and `gh ssh-key add` is called; git identity defaults from `gh api user` (name/login, email or noreply) and confirmed via `ask`.
- [ ] Implement: login `gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key` if `gh auth status` fails; if `gh ssh-key list` fails → `gh auth refresh -h github.com -s admin:public_key`; `gh config set git_protocol ssh`; add `github.com` to `~/.ssh/known_hosts` via `ssh-keyscan` if missing; identity via `apply_git_config`.
- [ ] `make test` PASS. Commit.

### Task 6: Runtimes, Claude Code, Xcode

**Files:** Create `lib/runtimes.sh`, `lib/claude.sh`, `lib/xcode.sh`, `tests/tools.bats`, stubs `mise`, `xcode-select`, `xcodebuild`.

- [ ] Tests: `install_runtimes` calls `mise install`, `mise upgrade`, `mise prune --yes`; `install_claude` skips when `~/.local/bin/claude` exists, otherwise runs installer via curl; `setup_xcode` with no `$MBI_APPS_DIR/Xcode.app` → `note_todo` with App Store instructions, no sudo calls; with Xcode present → `xcode-select -s`, `xcodebuild -license accept`, `-runFirstLaunch`, and `-downloadPlatform iOS` only when `xcrun simctl list runtimes` lacks iOS.
- [ ] Implement. `make test` PASS. Commit.

### Task 7: Orchestration and bootstrap

**Files:** Create `setup.sh`, `install.sh`, `tests/smoke.bats`.

- [ ] Smoke tests (all stubs, temp HOME): `bash setup.sh` completes, writes log, prints summary; second run creates no new `*.backup-*`; `bash install.sh` from checkout uses local dir; `cat install.sh | bash` downloads tarball via stub curl (stub serves `tar` of the repo with a `macbook-installer-main/` prefix) and runs setup; non-admin stub `id` → exit 1 with Czech message and no sudo call; failing stub `mise` → ERR trap message with log path, exit non-zero.
- [ ] Implement `setup.sh`: intro text, `preflight_checks`, `start_sudo_keepalive`, `ensure_homebrew`, `setup_github`, `install_packages`, `install_runtimes`, `install_claude`, `install_dotfiles`, `setup_xcode`, `print_summary`. Logging via `exec > >(tee -a "$MBI_LOG") 2>&1`.
- [ ] Implement `install.sh`: if `lib/` exists next to `BASH_SOURCE`, use that; else download `https://github.com/jiripisa/macbook-installer/archive/refs/heads/main.tar.gz` into `mktemp -d` with `--strip-components 1`; `exec /bin/bash "$root/setup.sh" < "${MBI_TTY:-/dev/tty}"`.
- [ ] `make test` PASS. Commit.

### Task 8: README, CI, publish

**Files:** Create `README.md`, `.github/workflows/test.yml`.

- [ ] README (Czech): what it does, prerequisites (admin account, GitHub account, internet), how to open Terminal, the one command, what will be asked, what to do after (Xcode from App Store + re-run, open Ghostty, `claude` login, `flutter doctor`), how to update (run again), where the log is, `~/.zshrc.local`.
- [ ] CI: `macos-latest`, `brew install shellcheck bats-core`, `make test`.
- [ ] `make test` PASS; `git status` clean before commit; commit.
- [ ] `gh repo create jiripisa/macbook-installer --public --source . --push` (push approved by owner for this task); verify CI run green.

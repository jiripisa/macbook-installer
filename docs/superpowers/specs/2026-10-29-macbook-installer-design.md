# MacBook Installer — Design

Date: 2026-10-29
Owner: Jiří Píša (GitHub `jiripisa`)

## Intent

A one-command setup script that turns a brand-new, out-of-the-box MacBook Air
into a ready-to-use development machine for the owner's son, who is starting
to learn programming. The son runs it himself (the father is nearby if
something goes wrong), so the script must explain what it does, ask for input
clearly, and fail with understandable messages.

The setup is modelled on the father's own Mac, minus his personal/work-specific
bits, and simplified where his setup would confuse a beginner.

## Goals

- The son opens Terminal.app on a fresh Mac, pastes one command from the
  README, and ends up with a configured development environment.
- Development environments for Java, Node.js, Python, Go, Rust (via mise).
- Ability to develop and build native macOS apps from the terminal, without
  having to open Xcode.
- GitHub ready to use: `gh` authenticated, SSH key generated and added to the
  son's (already existing) GitHub account if not already there.
- Safe to re-run: re-running installs what is missing and upgrades what is
  outdated. Re-running is also the update mechanism.
- Things already present on the Mac (e.g. Homebrew, git, Chrome) are not
  reinstalled, but are checked and upgraded to the current version.

## Non-goals

- No macOS system tweaks (Finder settings such as showing extensions/hidden
  files, Dock, keyboard, etc.). Developer tooling only.
- Xcode itself is **not** installed by the script; the son installs it from
  the App Store manually.
- No copying of the father's work/personal configuration (JP4 notarization
  variables, `KUBECONFIG`, `jira`/`jiratui`, `treeji`, `gtcmnt`, `dotfiles`
  alias, Docker Desktop leftovers).
- No niche tools from the father's machine (ollama, platformio, emscripten,
  yt-dlp, aider, sqlcmd, poppler, rtmidi, sdl2-compat, jetbrains-toolbox,
  codex, pearcleaner, antidote, atuin).

## Anti-goals

- **Do not replace standard commands.** No aliases for `ls` → `eza`,
  `cat` → `bat`, `cd` → `zoxide`. The son must learn the commands that
  tutorials use. The tools may be installed but are only reachable under
  their own names.
- No interactive surprises in the middle of a long run: the password is asked
  at the very start; GitHub login and git identity confirmation happen right
  after Homebrew and `gh` are installed (the script says up front that this
  will come); everything after that runs unattended.
- Never silently destroy existing config or the son's own changes: existing
  dotfiles are backed up before being replaced, and the son's personal
  settings live in files the script never touches (see "Config ownership").

## Delivery

- Public GitHub repo `jiripisa/macbook-installer` (created only after this
  design is approved; never pushed without the owner's explicit confirmation).
- README in **Czech** with a clear, beginner-proof guide: open Terminal
  (Spotlight → "Terminal"), paste this one command, what will be asked,
  what to do at the end (install Xcode from App Store, re-run, open Ghostty).
- Entry command (shape):
  `curl -fsSL https://raw.githubusercontent.com/jiripisa/macbook-installer/main/install.sh | bash`
- **Language:** all user-facing messages (script output, README) in Czech.
  Code, identifiers, code comments, and commit messages in English.

## Constraints

- Must work on a pristine Mac: only what ships with macOS is available at
  start (`/bin/bash` 3.2, `/bin/zsh`, `curl`). No git until Command Line
  Tools are installed.
- Run via `curl … | bash`: stdin is the script itself, so any interactive
  prompt must read from `/dev/tty`.
- Target: Apple Silicon MacBook Air, current macOS (Homebrew prefix
  `/opt/homebrew`).
- Default shell is zsh; config targets zsh.
- Must not be run end-to-end on the father's machine for testing — it would
  overwrite his configuration.
- The son's macOS user **will be an administrator** (owner confirmed). The
  script still checks this at the start and stops with a clear Czech message
  if the user is not an admin.

## Flow

1. **Intro** — explain what will happen, roughly how long, and that a GitHub
   login will be needed after a few minutes; check admin rights; ask for the
   Mac password (sudo) and keep it alive for the run.
2. **Base** — Command Line Tools (via the Homebrew installer) and Homebrew.
   The official installer runs even when Homebrew is already present: a Mac
   can have an old Homebrew that does not recognise the current macOS and no
   Command Line Tools (so no git), and `brew update` alone cannot recover from
   that (seen on a real run: macOS 27.2). The installer installs the CLT,
   checks out the latest Homebrew and updates it. Then install `gh` and `git`
   from Homebrew.
3. **GitHub** — `gh auth login` via browser; generate an `ed25519` SSH key
   **without a passphrase** if none exists and upload it to the account if not
   already there; set git protocol to SSH. Git `user.name` / `user.email`
   pre-filled from the GitHub account and confirmed by the son. If the
   account's email is private (API returns none), pre-fill the GitHub noreply
   address (`<id>+<login>@users.noreply.github.com`).
   From here on the run is unattended.
4. **Brewfile** (kept in the repo) — formulae and casks below. A cask app
   already installed outside Homebrew (e.g. a manually installed Chrome) is
   taken over with `brew install --cask --adopt` so Homebrew manages it from
   then on.
5. **mise runtimes** — global config below.
6. **Claude Code** — official native installer (lands in `~/.local/bin`).
7. **Config files** — see "Config ownership".
8. **Xcode** — if `/Applications/Xcode.app` is missing, print instructions to
   install it from the App Store and re-run the script. If present: point
   `xcode-select` at it, accept the license, run first-launch setup, and
   download the iOS platform (simulator) if missing
   (`xcodebuild -downloadPlatform iOS`, several GB) so Flutter/Swift iPhone
   apps can run in the simulator.
9. **Summary** — what was installed/upgraded/skipped, what remains to do
   manually (install Xcode, quit Terminal and open Ghostty, log in to
   Claude Code), path to the log file.

## Re-run behaviour

Re-running is the update mechanism:

- `brew update` + `brew upgrade` — upgrades **everything** installed via
  Homebrew, including tools the son installed himself.
- Self-updating cask apps (Chrome, VS Code, Zed, …) are **not** force-upgraded
  (no `--greedy`); they update themselves.
- `mise upgrade` moves `latest`/`lts` runtimes to the newest versions;
  old versions are pruned (`mise prune`).
- Claude Code updates itself; the installer step is skipped if present.
- Steps already done (SSH key on GitHub, `gh` logged in, Xcode configured)
  are detected and skipped.

## Config ownership

The script owns some files and must never touch the son's own ones:

- **Managed files** — `.zprofile`, `.zshrc`, `~/.config/starship.toml`,
  Ghostty config, global gitignore, and the mise tool list in
  `~/.config/mise/conf.d/macbook-installer.toml` (so `~/.config/mise/config.toml`
  stays free for the son's own `mise use -g`). They are kept in sync with the repo:
  if the file on disk differs from the repo version, it is backed up with a
  timestamp suffix and replaced; if identical, nothing happens (no backup
  spam on re-runs).
- **Son's files, never touched** — `~/.zshrc.local` (sourced at the end of
  the managed `.zshrc` if it exists; the script may create it empty with a
  short Czech comment explaining its purpose, but never overwrites it).
- **`.gitconfig`** — not replaced as a file; the script sets the individual
  values via `git config --global`, so anything else the son adds stays.

## Package set

### Homebrew formulae

- Core: `git`, `gh`, `micro`, `mise`, `starship`
- Shell quality of life: `zsh-autosuggestions`, `zsh-syntax-highlighting`,
  `fzf`, `direnv`
- Installed, not aliased: `eza`, `bat`, `zoxide`
- Git tooling: `git-delta`, `lazygit`
- Misc CLI: `glow`, `jq`, `ripgrep`, `fd`, `uv`
- macOS app development from terminal: `xcodegen`, `xcbeautify`,
  `swiftformat`, `swiftlint`
- iPhone apps with Flutter: `cocoapods`

### Homebrew casks

`ghostty`, `zed`, `visual-studio-code`, `google-chrome`, `orbstack`,
`font-jetbrains-mono-nerd-font`, `flutter`

Flutter was added by the owner after approval ("so he can make iPhone
apps"). Target is iOS only; Android tooling is out of scope.

### mise (`~/.config/mise/conf.d/macbook-installer.toml`)

- `java = "temurin-25"`
- `maven = "latest"`
- `node = "lts"` (LTS rather than latest — chosen for stability for a beginner)
- `python = "latest"`
- `go = "latest"`
- `rust = "latest"`

## Configuration content

### `.zprofile`

- `brew shellenv`
- (OrbStack adds its own init line on first launch — leave that to OrbStack.)

### `.zshrc` (based on the father's, trimmed)

- starship init
- zsh-autosuggestions, zsh-syntax-highlighting
- `mise activate zsh`
- `fzf --zsh`
- `direnv hook zsh`
- `~/.local/bin` on `PATH` (Claude Code)
- History prefix search on up/down arrows (`up-line-or-beginning-search`)
- `compinit`
- At the end: `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local`
- Explicitly **no** atuin, no `ls`/`cat`/`cd` aliases, no work functions.

### `starship.toml`

Copy of the father's `~/.config/starship.toml` (gruvbox/teal palette,
Nerd Font symbols).

### Ghostty

Minimal config modelled on the father's (`window-inherit-working-directory =
false`), using the JetBrains Mono Nerd Font.

### `.gitconfig` (values set via `git config --global`)

- `user.name`, `user.email` from the GitHub account (confirmed)
- `core.editor = micro`
- `core.pager = delta`, `[delta] navigate = true`, `side-by-side = true`
- `init.defaultBranch = main`
- `core.excludesFile = ~/.gitignore_global`

### Global gitignore

`.DS_Store`, `.envrc`, `**/.claude/settings.local.json`.

## Decided by Claude (owner may override)

- Node LTS instead of latest.
- Managed dotfiles backed up with timestamp only when they differ, then
  replaced; son's settings in `~/.zshrc.local` (owner agreed).
- Git identity pre-filled from GitHub; noreply address when email is private.
- GitHub login moved right after Homebrew + `gh` install so the long part runs
  unattended.
- Manually installed cask apps adopted by Homebrew (`--adopt`); no `--greedy`
  upgrades.
- `brew upgrade` upgrades everything; mise upgrades and prunes old versions.
- Script does not wait for Xcode; re-run handles Xcode setup.
- Atuin dropped (takes over up-arrow/history search, confusing for a beginner).
- `eza`/`bat`/`zoxide` installed but without aliases.
- Added beyond the father's setup: `jq`, `ripgrep`, `fd`, macOS CLI build
  tools (`xcodegen`, `xcbeautify`, `swiftformat`, `swiftlint`), `.DS_Store`
  in global gitignore.
- A log file of the whole run, path printed in the summary.

## Left to the builder

- How the script obtains the config files and Brewfile (clone the repo after
  git is available vs. download raw files).
- Script structure (single file vs. small modules), output styling, progress
  display.
- Exact idempotency checks per step.
- How to test without a fresh Mac (shellcheck, a dry-run mode, a macOS VM,
  etc.) — but never by running the real install on the owner's machine.

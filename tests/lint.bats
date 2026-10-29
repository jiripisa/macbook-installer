#!/usr/bin/env bats

load helpers

@test "no variable is directly followed by a non-ASCII character (bash 3.2 reads it as part of the name)" {
  LC_ALL=C run grep -nE '\$[A-Za-z_][A-Za-z0-9_]*[^ -~]' "$REPO_ROOT"/lib/*.sh "$REPO_ROOT/setup.sh" "$REPO_ROOT/install.sh"
  [ "$status" -eq 1 ] || { echo "$output"; return 1; }
}

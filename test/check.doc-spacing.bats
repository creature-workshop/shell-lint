#!/usr/bin/env bats
# Covers the doc-spacing check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/doc-spacing/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "doc spacing: flags a doc block below a closer and a typed line below an assignment" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE
: <<'CONST'
The remote every call reads.
CONST
__git__REMOTE=origin
# CONST: The branch the remote is read at.
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__doc_spacing__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:6:"
  assert_output --partial "lib/git/api.sh:10:"
  refute_output --partial "lib/git/api.sh:3:"
}

@test "doc spacing: accepts a doc below a blank line, below a directive, or opening the file" {
  __f="$(fixture lib/git/api.sh <<'FIX'
: <<'MODULE'
Git.
MODULE

# CONST: The remote every call reads.
__git__REMOTE=origin

# shellcheck disable=SC2034
# CONST: The branch the remote is read at.
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__doc_spacing__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "doc spacing: accepts a role's doc on the first line of its plugin's block" {
  __f="$(fixture lib/git/git.forge.op.sh <<'FIX'
: <<'DOC'
The git adaptor.
DOC
@forge.git() {
  : <<'FUN'
Prints the remote.
FUN
  @remote() {
    printf 'origin\n'
  }
  : <<'FUN'
Prints the branch.
FUN
  @branch() {
    printf 'main\n'
  }
}
FIX
)"

  run lint__checks__shell__doc_spacing__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "git.forge.op.sh:11:"
  refute_output --partial "git.forge.op.sh:5:"
}

@test "doc spacing: honours the allow marker within three lines above" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

__git__REMOTE=origin
# doc-spacing-check: allow -- the pair reads as one table
# CONST: The branch the remote is read at.
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__doc_spacing__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}


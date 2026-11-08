#!/usr/bin/env bats
# Covers the assignment-label check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/assignment-label/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
}

@test "assignment label: flags a constant's doc that opens on DOC" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

: <<'DOC'
The remote every call reads.
DOC
__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:7:"
  assert_output --partial "so it opens on CONST"
}

@test "assignment label: accepts CONST, VAR and PUB_CONST where the names earn them" {
  __f="$(fixture lib/versions/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Versions.
MODULE

: <<'CONST'
The tag prefix.
CONST
__versions__PREFIX=v

: <<'VAR'
The tags seen so far, space-joined.
VAR
__versions__seen=""

: <<'PUB_CONST'
The bump levels, in order.
PUB_CONST
@enum versions__LEVEL PATCH MINOR MAJOR
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "assignment label: flags PUB_CONST above a private name" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_CONST'
The remote every call reads.
PUB_CONST
__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "private to its module; open on CONST"
}

@test "assignment label: an entrypoint's names take no PUB_" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

: <<'CONST'
Where the checks live.
CONST
CHECKS_DIR="$SHELLOPS_DIR/lib"
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "assignment label: flags CONST on a block that documents no root assignment" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'CONST'
The checked-out branch.
CONST
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "not followed by a root assignment"
}

@test "assignment label: a blank line parts a doc from the assignment below it" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'CONST'
A note that documents nothing.
CONST

__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:3:"
  assert_output --partial "not followed by a root assignment"
}

@test "assignment label: leaves a function's PUB_FUN alone" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
The checked-out branch.
PUB_FUN
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "assignment label: a file doc above a constant is the file's, and stays MODULE" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git as the library reads it.
MODULE

__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "assignment label: flags a constant right below a typed-documented one with no doc of its own" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

# CONST: The remote every call reads.
__git__REMOTE=origin
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:9:"
  assert_output --partial "__git__BRANCH sits right below a documented assignment with no doc of its own"
}

@test "assignment label: every member of a run below a heredoc-documented constant is reported" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

: <<'CONST'
The remote every call reads.
CONST
__git__REMOTE=origin
__git__BRANCH=main
__git__DEPTH=1
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:11:"
  assert_output --partial "lib/git/api.sh:12:"
}

@test "assignment label: accepts a run of constants each carrying its own typed line" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

# CONST: The remote every call reads.
__git__REMOTE=origin
# CONST: The branch the remote is read at.
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "assignment label: a blank line below a documented constant parts the next from its doc" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

# CONST: The remote every call reads.
__git__REMOTE=origin

__git__BRANCH=main
FIX
)"

  run lint__checks__shell__assignment_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}


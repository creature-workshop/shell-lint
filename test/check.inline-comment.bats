#!/usr/bin/env bats
# Covers the inline-comment check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/inline-comment/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
}

@test "inline comment: flags a comment inside a function body, and leaves a shellcheck directive alone" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
The checked-out branch.
PUB_FUN
git__current_branch() {
  # shellcheck disable=SC2312
  # detached HEAD prints nothing
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__inline_comment__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:8:"
  assert_output --partial "inside a function body"
  refute_output --partial "lib/git/api.sh:7:"
}

@test "inline comment: a typed comment above a constant is right when its label is the name's, and a bare one is not" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

# CONST: the remote every call reads.
__git__REMOTE=origin

# The default branch.
__git__BRANCH=main

# CONST: the tag prefix
git__PREFIX=v
FIX
)"

  run lint__checks__shell__inline_comment__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  refute_output --partial "lib/git/api.sh:3:"
  assert_output --partial "lib/git/api.sh:6:"
  assert_output --partial "leads with no label; open it with # CONST:"
  assert_output --partial "lib/git/api.sh:9:"
  assert_output --partial "leads with CONST; the name earns PUB_CONST"
}

@test "inline comment: a typed comment that runs past one line is a finding" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

# CONST: The remote every call reads, which GIT_REMOTE
# names and origin stands in for.
__git__REMOTE=origin
# CONST: The branch the remote is read at.
__git__BRANCH=main
FIX
)"

  run lint__checks__shell__inline_comment__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:7:"
  assert_output --partial "runs to 2 lines"
  refute_output --partial "lib/git/api.sh:10:"
}

@test "inline comment: flags a root comment above a function and one above nothing, and honours the allow marker" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

# Runs the checks.
main() {
  :
}

# inline-comment-check: allow -- the case the rule did not foresee
# A note that stays.
import "$SHELL_LINT_DIR/shell/lint/api.sh"

# Another note.
import "$SHELLOPS_DIR/lib/git/api.sh"
FIX
)"

  run lint__checks__shell__inline_comment__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/lint:3:"
  assert_output --partial "above a function"
  refute_output --partial "cli/lint:9:"
  assert_output --partial "cli/lint:12:"
  assert_output --partial "above no constant or variable"
}


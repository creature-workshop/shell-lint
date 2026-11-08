#!/usr/bin/env bats
# Covers the function-label check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/function-label/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
}

@test "function label: flags a library function doc that opens on DOC" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
The checked-out branch.
DOC
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:3:"
  assert_output --partial "opens on PUB_FUN"
}

@test "function label: accepts PUB_FUN on a public function and FUN on a private one" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
The checked-out branch.
PUB_FUN
git__current_branch() {
  __git__ref HEAD
}

: <<'FUN'
The short name of a ref.
FUN
__git__ref() {
  git symbolic-ref --short "$1"
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "function label: flags PUB_FUN above a private name, naming the reach" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
The short name of a ref.
PUB_FUN
__git__ref() {
  git symbolic-ref --short "$1"
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "private to its module; open on FUN"
}

@test "function label: flags FUN above a public library function" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'FUN'
The checked-out branch.
FUN
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "which is public; open on PUB_FUN"
}

@test "function label: an entrypoint's functions and a plugin's roles take FUN" {
  __cli="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

: <<'FUN'
Runs the checks.
FUN
main() {
  :
}
FIX
)"
  __plugin="$(fixture lib/forks/forks.profile.op.sh <<'FIX'
#!/usr/bin/env bash

:<<'DOC'
The forks profiler: one profile plugin.
DOC
@profile.forks() {
  :<<'FUN'
Counts forks.
FUN
  @summary() {
    printf 'Counts forks.\n'
  }
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__cli" "$__plugin"
  assert_success
  assert_output ""
}

@test "function label: flags PUB_FUN on an entrypoint's function" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

: <<'PUB_FUN'
Runs the checks.
PUB_FUN
main() {
  :
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "an entrypoint's function; open on FUN"
}

@test "function label: flags FUN on a block that documents no function" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git.
MODULE

: <<'FUN'
The remote every call reads.
FUN
__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:7:"
  assert_output --partial "not followed by a function"
}

@test "function label: a blank line parts a doc from the function below it, so the doc is not the function's" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git as the library reads it.
MODULE

git__current_branch() {
  git symbolic-ref --short HEAD
}

: <<'FUN'
A note that documents nothing.
FUN

__git__ref() {
  :
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  refute_output --partial "lib/git/api.sh:3:"
  assert_output --partial "lib/git/api.sh:11:"
  assert_output --partial "not followed by a function"
}

@test "function label: leaves a constant's DOC alone" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
The remote every call reads.
DOC
__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "function label: a shellcheck directive between the doc and the function does not part them" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
The checked-out branch.
DOC
# shellcheck disable=SC2120
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:3:"
  assert_output --partial "opens on PUB_FUN"
}

@test "function label: a structs verb at column zero is public; an indented role is not" {
  __verbs="$(fixture lib/structs/api.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
Prints an empty array.
PUB_FUN
@arr() {
  printf '[]\n'
}
FIX
)"
  __role="$(fixture lib/structs/types/int.type.op.sh <<'FIX'
#!/usr/bin/env bash

:<<'DOC'
The int type.
DOC
@type.int() {
  :<<'PUB_FUN'
Validates an integer.
PUB_FUN
  @is() {
    :
  }
}
FIX
)"

  run lint__checks__shell__function_label__run "$SHELLOPS_ROOTS" "$__verbs" "$__role"
  assert_failure
  assert_output --partial "int.type.op.sh:7:"
  assert_output --partial "a plugin's role; open on FUN"
  refute_output --partial "structs/api.sh"
}


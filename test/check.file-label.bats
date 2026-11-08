#!/usr/bin/env bats
# Covers the file-label check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/file-label/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
}

@test "file label: flags a library file doc that opens on DOC" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Git as the library reads it.
DOC

git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:3:"
  assert_output --partial "file doc opens on DOC"
}

@test "file label: accepts MODULE on a file doc, with a constant's doc below it" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

import "$SHELLOPS_DIR/lib/structs/api.sh"

: <<'MODULE'
Git as the library reads it.
MODULE

: <<'DOC'
The remote every call reads.
DOC
__git__REMOTE=origin

git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: accepts FRAGMENT on a file its own module imports" {
  __frag="$(fixture lib/git/branches.sh <<'FIX'
#!/bin/sh

: <<'FRAGMENT'
The branch questions git/api.sh answers.
FRAGMENT

git__branch_exists() {
  git show-ref --quiet "refs/heads/$1"
}
FIX
)"
  __api="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

import "$SHELLOPS_DIR/lib/git/branches.sh"

: <<'MODULE'
Git as the library reads it.
MODULE
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__frag" "$__api"
  assert_success
  assert_output ""
}

@test "file label: flags an import of a FRAGMENT from another directory" {
  __frag="$(fixture lib/git/branches.sh <<'FIX'
#!/bin/sh

: <<'FRAGMENT'
The branch questions git/api.sh answers.
FRAGMENT

git__branch_exists() {
  git show-ref --quiet "refs/heads/$1"
}
FIX
)"
  __user="$(fixture lib/releases/api.sh <<'FIX'
#!/bin/sh

import \
  "$SHELLOPS_DIR/lib/structs/api.sh" \
  "$SHELLOPS_DIR/lib/git/branches.sh"

: <<'MODULE'
Releases.
MODULE
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__frag" "$__user"
  assert_failure
  assert_output --partial "lib/releases/api.sh:5:"
  assert_output --partial "a FRAGMENT of lib/git"
}

@test "file label: records every import on one line of an entrypoint, and reports the fragment among them" {
  __frag="$(fixture lib/git/branches.sh <<'FIX'
#!/bin/sh

: <<'FRAGMENT'
The branch questions git/api.sh answers.
FRAGMENT

git__branch_exists() {
  git show-ref --quiet "refs/heads/$1"
}
FIX
)"
  __user="$(fixture actions/release <<'FIX'
#!/usr/bin/env bash

import "$SHELLOPS_DIR/lib/structs/api.sh" "$SHELLOPS_DIR/lib/git/branches.sh"

USAGE="$(cat <<'HELP'
Cuts a release.
HELP
)"
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__frag" "$__user"
  assert_failure
  assert_output --partial "actions/release:3:"
  assert_output --partial "imports lib/git/branches.sh, a FRAGMENT of lib/git"
  refute_output --partial "lib/structs/api.sh"
}

@test "file label: a CONST block above an enum documents the enum, and the MODULE below it is the file doc" {
  __f="$(fixture lib/node/api.sh <<'FIX'
#!/bin/sh

: <<'CONST'
The package managers a lockfile commits a project to.
CONST
@enum __node__PACKAGE_MANAGER PNPM YARN NPM

: <<'MODULE'
Node.
MODULE
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: flags MODULE on a doc that sits on a function" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
The checked-out branch.
MODULE
git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:3:"
  assert_output --partial "documents the definition below it"
}

@test "file label: flags FRAGMENT on a block that is not the file's first" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git as the library reads it.
MODULE

: <<'FRAGMENT'
The remote every call reads.
FRAGMENT
__git__REMOTE=origin
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/git/api.sh:7:"
  assert_output --partial "not the file's first"
}

@test "file label: flags MODULE on an entrypoint's doc" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

: <<'MODULE'
Runs the checks.
MODULE

main() {
  :
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "an entrypoint documents itself in its usage, opened on HELP"
}

@test "file label: a doc block followed by a blank line is the file's, whatever sits below the blank" {
  __f="$(fixture lib/git/api.sh <<'FIX'
#!/bin/sh

: <<'MODULE'
Git as the library reads it.
MODULE

git__current_branch() {
  git symbolic-ref --short HEAD
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: flags an entrypoint whose top doc is a doc block rather than its usage" {
  __f="$(fixture actions/git/sign <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Signs every commit this checkout makes.
DOC

main() {
  :
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "actions/git/sign:3:"
  assert_output --partial "opened on HELP"
}

@test "file label: leaves a library file whose first doc sits on a function alone" {
  __f="$(fixture lib/log/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Prints its arguments to stderr.
DOC
log() {
  printf '%s\n' "$@" >&2
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: leaves a plugin's doc alone" {
  __f="$(fixture lib/forks/forks.profile.op.sh <<'FIX'
#!/usr/bin/env bash

:<<'DOC'
The forks profiler: one profile plugin.
DOC
@profile.forks() {
  @summary() { printf 'Counts forks.\n'; }
}
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: honours its allow marker on a file that is neither a module nor an entrypoint" {
  __f="$(fixture cli/env <<'FIX'
#!/usr/bin/env bash

# file-label-check: allow -- sourced, neither a module nor an entrypoint
: <<'DOC'
Activates the toolchain.
DOC

if [ -f x ]; then
  :
fi
FIX
)"

  run lint__checks__shell__file_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "file label: a consumer's module under its shell home is a library file, its doc opening on MODULE" {
  __f="$(fixture shell/thing/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Reading things, for a consumer.
DOC

thing__read() {
  printf 'thing\n'
}
FIX
)"

  @obj at3
  PROJ="$BATS_TEST_TMPDIR" run lint__checks__shell__file_label__run "$at3" "$__f"
  assert_failure
  assert_output --partial "shell/thing/api.sh:3: file doc opens on DOC; a library file's opens on MODULE"

  __g="$(fixture src/thing/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Reading things, for a consumer whose shell is its product.
DOC

thing__read() {
  printf 'thing\n'
}
FIX
)"

  @obj at4
  PROJ="$BATS_TEST_TMPDIR" run lint__checks__shell__file_label__run "$at4" "$__g"
  assert_failure
  assert_output --partial "src/thing/api.sh:3: file doc opens on DOC; a library file's opens on MODULE"
}

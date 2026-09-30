#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/comments/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "duplicate file doc: flags an entrypoint carrying a doc block and a USAGE" {
  __f="$(fixture cli/both.sh <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Applies the labels a review earned.
DOC

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/both.sh:3:"
}

@test "duplicate file doc: flags a usage defined as a function, not a variable" {
  __f="$(fixture cli/dynamic.sh <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Installs the registered tools.
DOC

__tools_api__lockfile="$PROJ/ops.lock"

main() {
  case "$1" in
    -h|--help) __tools_api__usage; exit 0 ;;
  esac
}

__tools_api__usage() {
  printf 'Usage: ops install\n'
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/dynamic.sh:3:"
}

@test "duplicate file doc: accepts a doc block sitting on the file's first function" {
  __f="$(fixture cli/first_function.sh <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

: <<'DOC'
Reads the labels off the review being built.
DOC
read_labels() {
  printf 'type/feature\n'
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: accepts an entrypoint whose only doc is its usage" {
  __f="$(fixture cli/usage_only.sh <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: accepts a doc block that documents a function" {
  __f="$(fixture cli/function_doc.sh <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

: <<'DOC'
Reads the labels off the review being built.
DOC
read_labels() {
  printf 'type/feature\n'
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: accepts an entrypoint with a file doc and no usage" {
  __f="$(fixture cli/doc_only.sh <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Posts a comment asking for issue references.
DOC

main() {
  printf 'posted\n'
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: flags a USAGE before the first function, wherever the file sits" {
  __f="$(fixture init <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Initializes a consumer repository for shellops.
DOC

USAGE="$(cat <<EOF
Initializes a consumer repository for shellops.
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "init:3:"
}

@test "duplicate file doc: flags a usage function defined far below the code it describes" {
  __f="$(fixture lib/thing/dispatch.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Dispatches a thing to the reader that handles it.
DOC

THINGS_DIR="$SHELLOPS_DIR/things"

main() {
  dispatch_usage
}

dispatch_usage() {
  printf 'Usage: dispatch <thing>\n'
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/thing/dispatch.sh:3:"
}

@test "duplicate file doc: reads a USAGE below the first function as that code's own string" {
  __f="$(fixture lib/thing/api.sh <<'FIX'
#!/bin/sh

: <<'DOC'
Reading things.
DOC

THINGS_DIR="$SHELLOPS_DIR/things"

read_thing() {
  printf 'thing\n'
}

USAGE="unused"
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: accepts a constant's doc above the usage, since it opens on CONST" {
  __f="$(fixture cli/constant_doc.sh <<'FIX'
#!/usr/bin/env bash

: <<'CONST'
The label set a review can earn, in the order the entrypoint applies
them.
CONST
LABELS="type/feature type/fix"

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: leaves a floating doc block below the first function alone" {
  __f="$(fixture cli/late_block.sh <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Applies the labels a review earned.
EOF
)"

main() {
  log "$USAGE"
}

: <<'DOC'
The label set a review can earn, in the order they are applied.
DOC

LABELS="type/feature type/fix"
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "oversized doc block: flags a function doc past the twelve-line cap" {
  __f="$(fixture lib/wordy.sh <<'FIX'
: <<'DOC'
One line of it.
Two lines of it.
Three lines of it.
Four lines of it.
Five lines of it.
Six lines of it.
Seven lines of it.
Eight lines of it.
Nine lines of it.
Ten lines of it.
Eleven lines of it.
Twelve lines of it.
Thirteen lines of it.
DOC
speak() {
  printf 'spoken\n'
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "function doc doc block runs 13 prose lines (cap 12)"
}

@test "oversized doc block: gives the module header the wider cap" {
  __f="$(fixture lib/header.sh <<'FIX'
#!/bin/sh

: <<'DOC'
One line of it.
Two lines of it.
Three lines of it.
Four lines of it.
Five lines of it.
Six lines of it.
Seven lines of it.
Eight lines of it.
Nine lines of it.
Ten lines of it.
Eleven lines of it.
Twelve lines of it.
Thirteen lines of it.
DOC

import "$SHELLOPS_DIR/lib/thing/api.sh"

speak() {
  printf 'spoken\n'
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "oversized doc block: treats a block sitting on a function as a function doc" {
  __f="$(fixture lib/first_is_a_function.sh <<'FIX'
#!/bin/sh

: <<'DOC'
One line of it.
Two lines of it.
Three lines of it.
Four lines of it.
Five lines of it.
Six lines of it.
Seven lines of it.
Eight lines of it.
Nine lines of it.
Ten lines of it.
Eleven lines of it.
Twelve lines of it.
Thirteen lines of it.
DOC
speak() {
  printf 'spoken\n'
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "function doc doc block runs 13 prose lines (cap 12)"
}

@test "oversized doc block: does not count blank lines, sections, or their content" {
  __f="$(fixture lib/tabulated.sh <<'FIX'
: <<'DOC'
One line of it.
Two lines of it.
Three lines of it.

Parameters:
  first   the first of them
  second  the second of them
  third   the third of them
  fourth  the fourth of them
  fifth   the fifth of them
  sixth   the sixth of them
  seventh the seventh of them
  eighth  the eighth of them
  ninth   the ninth of them
  tenth   the tenth of them

Returns:
  the tabulated thing
DOC
tabulate() {
  printf 'tabulated\n'
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "oversized doc block: measures indentation against the block's own baseline" {
  __f="$(fixture lib/indented.sh <<'FIX'
: <<'DOC'
  One line of it.
  Two lines of it.
  Three lines of it.
  Four lines of it.
  Five lines of it.
  Six lines of it.
  Seven lines of it.
  Eight lines of it.
  Nine lines of it.
  Ten lines of it.
  Eleven lines of it.
  Twelve lines of it.
  Thirteen lines of it.
DOC
speak() {
  printf 'spoken\n'
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "runs 13 prose lines"
}

@test "oversized doc block: leaves a long run of # comments alone" {
  __f="$(fixture lib/rationale.sh <<'FIX'
# One line of it.
# Two lines of it.
# Three lines of it.
# Four lines of it.
# Five lines of it.
# Six lines of it.
# Seven lines of it.
# Eight lines of it.
# Nine lines of it.
# Ten lines of it.
# Eleven lines of it.
# Twelve lines of it.
# Thirteen lines of it.
git config --global http.extraheader "$AUTH"
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "oversized doc block: leaves a long data heredoc alone" {
  __f="$(fixture lib/usage_text.sh <<'FIX'
speak() {
  cat <<EOF
One line of it.
Two lines of it.
Three lines of it.
Four lines of it.
Five lines of it.
Six lines of it.
Seven lines of it.
Eight lines of it.
Nine lines of it.
Ten lines of it.
Eleven lines of it.
Twelve lines of it.
Thirteen lines of it.
EOF
}
FIX
)"

  run lint__comments__comment_lint_no_oversized_doc_block "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "backward reference: flags the markers in a doc block" {
  __f="$(fixture lib/history.sh <<'FIX'
: <<'DOC'
Resolves a suite, formerly "colocate".
DOC
resolve() {
  printf 'resolved\n'
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/history.sh:2:"
}

@test "backward reference: flags the markers in a # comment" {
  __f="$(fixture lib/inline.sh <<'FIX'
resolve() {
  # This used to be a lookup table.
  printf 'resolved\n'
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/inline.sh:2:"
}

@test "backward reference: accepts 'used to' meaning a purpose" {
  __f="$(fixture lib/purpose.sh <<'FIX'
# The type pattern, used to guard mutations against the wrong container.
resolve() {
  printf 'resolved\n'
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "backward reference: accepts 'no longer' describing a present condition" {
  __f="$(fixture lib/condition.sh <<'FIX'
: <<'DOC'
Drops the area paths that no longer exist on disk.
DOC
prune() {
  printf 'pruned\n'
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "backward reference: accepts hyphen-joined 'previously' modifying a noun" {
  __f="$(fixture lib/adjective.sh <<'FIX'
: <<'DOC'
Reports when a previously-clean repo grows unmapped paths.
DOC
report() {
  printf 'reported\n'
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "backward reference: leaves data heredocs alone, being output not commentary" {
  __f="$(fixture lib/help_text.sh <<'FIX'
speak() {
  cat <<EOF
Reads the manifest, formerly known as the lockfile.
EOF
}
FIX
)"

  run lint__comments__comment_lint_no_backward_reference "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "doc block tracker: flags a marker inside a doc block" {
  __f="$(fixture lib/pending.sh <<'FIX'
: <<'DOC'
Reports whether the version parses.

TODO(OPS-237): the builtin duplicates this and should reuse it.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run lint__comments__comment_lint_no_doc_block_tracker "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/pending.sh:4:"
}

@test "doc block tracker: leaves a marker beside code alone" {
  __f="$(fixture lib/beside.sh <<'FIX'
is_valid() {
  # TODO(OPS-237): fold this into the shared matcher.
  printf 'true\n'
}
FIX
)"

  run lint__comments__comment_lint_no_doc_block_tracker "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "doc block tracker: leaves a bare issue id in a doc block alone" {
  __f="$(fixture lib/example.sh <<'FIX'
: <<'DOC'
Pre-fills from the branch name (e.g. jeff/ops-82-something -> OPS-82).
DOC
prefill() {
  printf 'OPS-82\n'
}
FIX
)"

  run lint__comments__comment_lint_no_doc_block_tracker "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "cli: --check narrows to the one check named" {
  __f="$(cli_fixture lib/tracked.sh <<'FIX'
: <<'DOC'
Reports whether the version parses.

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check backward-reference "$__f"
  assert_success

  run "$SHELL_LINT_DIR/cli/lint" --check doc-block-tracker "$__f"
  assert_failure
}

@test "cli: with no --check, every check runs and each is reported" {
  __f="$(cli_fixture lib/messy.sh <<'FIX'
: <<'DOC'
Reports whether the version parses, formerly "is_semver".

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_failure
  assert_output --partial "Comment prose describes what the code does now"
  assert_output --partial "A doc block carries no TODO"
}

@test "cli: skips files that are not shell sources" {
  __f="$(cli_fixture notes.md <<'FIX'
A doc block opens with `: <<'DOC'`.
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

@test "cli: skips test sources, which document themselves as cases" {
  __f="$(cli_fixture test/some_helper.sh <<'FIX'
: <<'DOC'
Builds a fixture, formerly "make_file".
DOC
build() {
  printf 'built\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

@test "cli: skips a planning tree the same way it skips a test tree" {
  __f="$(cli_fixture planning/proto.sh <<'FIX'
: <<'DOC'
Applies the labels a review earned.
DOC
build() {
  printf 'built\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

@test "duplicate file doc: one run over many files names every file's finding" {
  __one="$(fixture cli/one.sh <<'FIX'
#!/usr/bin/env bash

: <<'DOC'
Does one thing.
DOC

USAGE="$(cat <<EOF
Does one thing.
EOF
)"
FIX
)"
  __two="$(fixture cli/two.sh <<'FIX'
#!/usr/bin/env bash
: <<'DOC'
Does another.
DOC

USAGE="$(cat <<EOF
Does another.
EOF
)"
FIX
)"

  run lint__comments__comment_lint_no_duplicate_file_doc "$SHELLOPS_ROOTS" "$__one" "$__two"
  assert_failure
  assert_output --partial "cli/one.sh:3:"
  assert_output --partial "cli/two.sh:2:"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__frag" "$__api"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__frag" "$__user"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__frag" "$__user"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "usage label: flags a USAGE heredoc that opens on EOF" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Usage: ops lint [files...]
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__comments__comment_lint_usage_label "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/lint:3:"
  assert_output --partial "opens on EOF"
}

@test "usage label: accepts HELP on the USAGE heredoc" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<HELP
Usage: ops lint [files...]
HELP
)"

main() {
  cat <<EOF
$USAGE
EOF
}
FIX
)"

  run lint__comments__comment_lint_usage_label "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "usage label: flags HELP on a heredoc that is not the usage" {
  __f="$(fixture lib/releases/api.sh <<'FIX'
#!/bin/sh

release_body() {
  cat <<HELP
Released.
HELP
}
FIX
)"

  run lint__comments__comment_lint_usage_label "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/releases/api.sh:4:"
  assert_output --partial "not assigned to USAGE"
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

  run lint__comments__comment_lint_file_label "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__cli" "$__plugin"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_function_label "$SHELLOPS_ROOTS" "$__verbs" "$__role"
  assert_failure
  assert_output --partial "int.type.op.sh:7:"
  assert_output --partial "a plugin's role; open on FUN"
  refute_output --partial "structs/api.sh"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_assignment_label "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
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

  run lint__comments__comment_lint_inline_comment "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_inline_comment "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_inline_comment "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_inline_comment "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/lint:3:"
  assert_output --partial "above a function"
  refute_output --partial "cli/lint:9:"
  assert_output --partial "cli/lint:12:"
  assert_output --partial "above no constant or variable"
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

  run lint__comments__comment_lint_doc_spacing "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_doc_spacing "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_doc_spacing "$SHELLOPS_ROOTS" "$__f"
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

  run lint__comments__comment_lint_doc_spacing "$SHELLOPS_ROOTS" "$__f"
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

  PROJ="$BATS_TEST_TMPDIR" run lint__comments__comment_lint_file_label "$(@obj)" "$__f"
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

  PROJ="$BATS_TEST_TMPDIR" run lint__comments__comment_lint_file_label "$(@obj)" "$__g"
  assert_failure
  assert_output --partial "src/thing/api.sh:3: file doc opens on DOC; a library file's opens on MODULE"
}

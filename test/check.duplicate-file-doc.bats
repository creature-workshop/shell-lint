#!/usr/bin/env bats
# Covers the duplicate-file-doc check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/duplicate-file-doc/api.sh"

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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__duplicate_file_doc__run "$SHELLOPS_ROOTS" "$__one" "$__two"
  assert_failure
  assert_output --partial "cli/one.sh:3:"
  assert_output --partial "cli/two.sh:2:"
}


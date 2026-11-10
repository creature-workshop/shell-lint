#!/usr/bin/env bats
# Covers the doc-block-tracker check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/doc-block-tracker/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
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

  run lint__checks__shell__doc_block_tracker__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__doc_block_tracker__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__doc_block_tracker__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}


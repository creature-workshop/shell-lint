#!/usr/bin/env bats
# Covers the backward-reference check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/backward-reference/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__backward_reference__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}


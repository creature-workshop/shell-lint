#!/usr/bin/env bats
# Covers the oversized-doc-block check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/oversized-doc-block/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
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

  run lint__checks__shell__oversized_doc_block__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}


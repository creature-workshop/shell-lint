#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/boolean-branches/api.sh"
}

@test "lint__checks__shell__boolean_branches__run: reports a five-line if/else of the constructors once, at the if line" {
  __f="$(fixture five_line.sh <<'FIX'
is_y() {
  if [ "$1" = y ]; then
    @true
  else
    @false
  fi
}
FIX
)"

  @obj at1
  run lint__checks__shell__boolean_branches__run "$at1" "$__f"
  assert_failure
  assert_line --index 0 --partial "$__f:2: predicate written as an if"
  assert_equal "${#lines[@]}" 1
}

@test "lint__checks__shell__boolean_branches__run: reports the branches the other way round, @false then @true" {
  __f="$(fixture inverted.sh <<'FIX'
is_not_y() {
  if [ "$1" = y ]; then
    @false
  else
    @true
  fi
}
FIX
)"

  @obj at2
  run lint__checks__shell__boolean_branches__run "$at2" "$__f"
  assert_failure
  assert_output --partial "$__f:2:"
}

@test "lint__checks__shell__boolean_branches__run: reports an if/else on one line" {
  __f="$(fixture one_line.sh <<'FIX'
is_y() {
  if [ "$1" = y ]; then @true; else @false; fi
}
FIX
)"

  @obj at3
  run lint__checks__shell__boolean_branches__run "$at3" "$__f"
  assert_failure
  assert_output --partial "$__f:2:"
}

@test "lint__checks__shell__boolean_branches__run: reports then and else written on their own lines, at the if" {
  __f="$(fixture own_lines.sh <<'FIX'
is_y() {
  if [ "$1" = y ]
  then @true
  else @false
  fi
}
FIX
)"

  @obj at4
  run lint__checks__shell__boolean_branches__run "$at4" "$__f"
  assert_failure
  assert_line --index 0 --partial "$__f:2:"
}

@test "lint__checks__shell__boolean_branches__run: reports a condition spread over continued lines, at its first line" {
  __f="$(fixture continued.sh <<'FIX'
is_open() {
  if [ "$(@get "$1" '.state')" = \
    open ]; then
    @true
  else
    @false
  fi
}
FIX
)"

  @obj at5
  run lint__checks__shell__boolean_branches__run "$at5" "$__f"
  assert_failure
  assert_output --partial "$__f:2:"
}

@test "lint__checks__shell__boolean_branches__run: reports each file's findings when several files are read in one run" {
  __a="$(fixture first.sh <<'FIX'
is_y() {
  if [ "$1" = y ]; then
    @true
  else
    @false
  fi
}
FIX
)"
  __b="$(fixture second.sh <<'FIX'
is_z() {
  if [ "$1" = z ]; then
    @true
  else
    @false
  fi
}
FIX
)"

  @obj at6
  run lint__checks__shell__boolean_branches__run "$at6" "$__a" "$__b"
  assert_failure
  assert_output --partial "$__a:2:"
  assert_output --partial "$__b:2:"
  assert_equal "${#lines[@]}" 2
}

@test "lint__checks__shell__boolean_branches__run: accepts a condition that is a list, which @succeeds cannot run" {
  __f="$(fixture list.sh <<'FIX'
is_open_y() {
  if [ "$(@get "$1" '.kind')" = y ] \
    && [ "$(@get "$1" '.state')" = open ]; then
    @true
  else
    @false
  fi
}
either() {
  if [ "$1" = y ] || [ "$1" = yes ]; then
    @true
  else
    @false
  fi
}
FIX
)"

  @obj at7
  run lint__checks__shell__boolean_branches__run "$at7" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__boolean_branches__run: accepts a guard that prints one constructor and returns" {
  __f="$(fixture guard.sh <<'FIX'
is_record() {
  if ! parsed="$(parse "$1" 2>/dev/null)"; then
    @false
    return 0
  fi
  @succeeds [ "$(@get "$parsed" '.kind')" = record ]
}
FIX
)"

  @obj at8
  run lint__checks__shell__boolean_branches__run "$at8" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__boolean_branches__run: accepts branches that do more than print a constructor" {
  __f="$(fixture does_more.sh <<'FIX'
is_y() {
  if [ "$1" = y ]; then
    log "y"
    @true
  else
    @false
  fi
}
same_answer() {
  if [ "$1" = y ]; then
    @true
  else
    @true
  fi
}
FIX
)"

  @obj at9
  run lint__checks__shell__boolean_branches__run "$at9" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__boolean_branches__run: skips heredoc bodies and keeps an allowed if" {
  __f="$(fixture prose.sh <<'FIX'
: <<'DOC'
The shape this check rejects:
  if [ "$1" = y ]; then
    @true
  else
    @false
  fi
DOC
is_y() {
  # structs-lint: allow -- kept to show the marker in this fixture
  if [ "$1" = y ]; then
    @true
  else
    @false
  fi
}
FIX
)"

  @obj at10
  run lint__checks__shell__boolean_branches__run "$at10" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__boolean_branches__run: accepts a path that is not a file" {
  @obj at11
  run lint__checks__shell__boolean_branches__run "$at11" "$BATS_TEST_TMPDIR/missing.sh"
  assert_success
  assert_output ""
}

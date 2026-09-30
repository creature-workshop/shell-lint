#!/usr/bin/env bats
# Covers shell/lint/awk_early_exit.awk through lint__awk_early_exit: which exits
# leave input unread, and which do not.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/api.sh"

  SAMPLE="$TEST_DIR/fixtures/lint/awk_early_exit.fixture.awk"
  DRAINS="$TEST_DIR/fixtures/lint/awk_drains_input.fixture.awk"
}

@test "lint__awk_early_exit: a bare exit in a rule is a finding" {
  run lint__awk_early_exit "$(@obj)" "$SAMPLE"

  assert_failure
  assert_output --partial "awk_early_exit.fixture.awk:19: exit with input left to read"
}

@test "lint__awk_early_exit: exit 0 and exit <expression> in a rule are answers too" {
  run lint__awk_early_exit "$(@obj)" "$SAMPLE"

  assert_output --partial "awk_early_exit.fixture.awk:20:"
  assert_output --partial "awk_early_exit.fixture.awk:21:"
}

@test "lint__awk_early_exit: a bare exit in a function a rule may call is a finding" {
  run lint__awk_early_exit "$(@obj)" "$SAMPLE"

  assert_output --partial "awk_early_exit.fixture.awk:10:"
}

@test "lint__awk_early_exit: an error exit, BEGIN, END, a string, a regex, a comment and an allowed line are not findings" {
  run lint__awk_early_exit "$(@obj)" "$SAMPLE"

  assert_equal "${#lines[@]}" 4
}

@test "lint__awk_early_exit: a program that records its answer and exits from END is clean" {
  run lint__awk_early_exit "$(@obj)" "$DRAINS"

  assert_success
  assert_output ""
}

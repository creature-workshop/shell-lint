#!/usr/bin/env bats
# Covers shell/lint/awk_early_exit.awk through lint__checks__awk__early_exit__run: which exits
# leave input unread, and which do not.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/awk/early-exit/api.sh"

  SAMPLE="$TEST_DIR/fixtures/lint/awk_early_exit.fixture.awk"
  DRAINS="$TEST_DIR/fixtures/lint/awk_drains_input.fixture.awk"
}

@test "lint__checks__awk__early_exit__run: a bare exit in a rule is a finding" {
  @obj at1
  run lint__checks__awk__early_exit__run "$at1" "$SAMPLE"

  assert_failure
  assert_output --partial "awk_early_exit.fixture.awk:19: exit with input left to read"
}

@test "lint__checks__awk__early_exit__run: exit 0 and exit <expression> in a rule are answers too" {
  @obj at2
  run lint__checks__awk__early_exit__run "$at2" "$SAMPLE"

  assert_output --partial "awk_early_exit.fixture.awk:20:"
  assert_output --partial "awk_early_exit.fixture.awk:21:"
}

@test "lint__checks__awk__early_exit__run: a bare exit in a function a rule may call is a finding" {
  @obj at3
  run lint__checks__awk__early_exit__run "$at3" "$SAMPLE"

  assert_output --partial "awk_early_exit.fixture.awk:10:"
}

@test "lint__checks__awk__early_exit__run: an error exit, BEGIN, END, a string, a regex, a comment and an allowed line are not findings" {
  @obj at4
  run lint__checks__awk__early_exit__run "$at4" "$SAMPLE"

  assert_equal "${#lines[@]}" 4
}

@test "lint__checks__awk__early_exit__run: a program that records its answer and exits from END is clean" {
  @obj at5
  run lint__checks__awk__early_exit__run "$at5" "$DRAINS"

  assert_success
  assert_output ""
}

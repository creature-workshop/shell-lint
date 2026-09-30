#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/config.sh"
}

@test "lint__config_load: reads and validates the repo lint.json" {
  run lint__config_load "$SHELLOPS_DIR/lint.json"
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 2
}

@test "lint__config_load: reads \$PROJ/lint.json when given no path" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj"
  echo '{"indent":{"width":4}}' > "$__proj/lint.json"

  PROJ="$__proj" run lint__config_load
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 4
}

@test "lint__config_load: a repo without lint.json gets the defaults" {
  PROJ="$BATS_TEST_TMPDIR" run lint__config_load
  assert_success
  assert_output "{}"
}

@test "lint__config_load: rejects a config that violates the schema" {
  echo '{"indent":{"width":"two"}}' > "$BATS_TEST_TMPDIR/bad.json"

  run lint__config_load "$BATS_TEST_TMPDIR/bad.json"
  assert_failure
}

@test "lint__config_load: rejects an unknown key" {
  echo '{"excludes":["planning"]}' > "$BATS_TEST_TMPDIR/bad.json"

  run lint__config_load "$BATS_TEST_TMPDIR/bad.json"
  assert_failure
}

@test "config readers: width, tabs, test trees, excludes and added_only come from the config" {
  __config='{"indent":{"width":4,"tabs":true},"tests":["spec"],"exclude":["planning","my dir"],"added_only":["raw-jq"]}'

  run lint__config_indent_width "$__config"
  assert_output "4"

  run lint__config_allow_tabs "$__config"
  assert_output "true"

  run lint__config_test_trees "$__config"
  assert_equal "$(@len "$output")" 1
  assert_equal "$(@get "$output" '.[0]')" "spec"

  run lint__config_excludes "$__config"
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[1]')" "my dir"

  run lint__config_added_only_checks "$__config"
  assert_equal "$(@get "$output" '.[0]')" "raw-jq"
}

@test "config readers: defaults apply when keys are absent" {
  run lint__config_indent_width '{}'
  assert_output "2"

  run lint__config_allow_tabs '{}'
  assert_output "false"

  run lint__config_test_trees '{}'
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[0]')" "test"

  run lint__config_excludes '{}'
  assert_equal "$(@len "$output")" 0

  run lint__config_added_only_checks '{}'
  assert_equal "$(@len "$output")" 0
}

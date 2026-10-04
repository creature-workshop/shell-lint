#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/config.sh"
}

@test "lint__config__load: reads and validates this repository's lint.json" {
  run lint__config__load "$SHELL_LINT_DIR/lint.json"
  assert_success
  assert_equal "$(@get "$output" '.decisions.form')" one-page
}

@test "lint__config__load: hands the read to shellops' config module when the shell defines it" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj"
  echo '{"indent":{"width":4}}' > "$__proj/lint.json"
  self__config__present() { @true; }
  self__config__load() { println '{"indent":{"width":7}}'; }

  PROJ="$__proj" run lint__config__load
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 7
}

@test "lint__config__load: a repository that shellops' config module finds no declaration in gets the defaults" {
  self__config__present() { @false; }
  self__config__load() { println '{"indent":{"width":7}}'; }

  PROJ="$BATS_TEST_TMPDIR" run lint__config__load
  assert_success
  assert_output "{}"
}

@test "lint__config__load: a lint.json that is not JSON is refused, naming the file" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj"
  echo '{bad' > "$__proj/lint.json"

  PROJ="$__proj" run lint__config__load
  assert_failure
  assert_output --partial "$__proj/lint.json does not read as JSON"
}

@test "lint__config__load: reads .ops/config/lint.yaml when the project has one" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj/.ops/config"
  printf 'indent:\n  width: 3\nadded_only:\n  - indent\n' > "$__proj/.ops/config/lint.yaml"

  PROJ="$__proj" run lint__config__load
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 3
  assert_equal "$(@get "$output" '.added_only[0]')" indent
}

@test "lint__config__load: the declaration under .ops/config wins over a lint.json beside it" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj/.ops/config"
  printf 'indent:\n  width: 3\n' > "$__proj/.ops/config/lint.yaml"
  echo '{"indent":{"width":4}}' > "$__proj/lint.json"

  PROJ="$__proj" run lint__config__load
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 3
}

@test "lint__config__load: a declaration that breaks the schema is refused" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj/.ops/config"
  printf 'indent:\n  width: two\n' > "$__proj/.ops/config/lint.yaml"

  PROJ="$__proj" run lint__config__load
  assert_failure
}

@test "lint__config__load: reads \$PROJ/lint.json when given no path and the project has not converted" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj"
  echo '{"indent":{"width":4}}' > "$__proj/lint.json"

  PROJ="$__proj" run lint__config__load
  assert_success
  assert_equal "$(@get "$output" '.indent.width')" 4
}

@test "lint__config__load: a repository with no declaration and no lint.json gets the defaults" {
  PROJ="$BATS_TEST_TMPDIR" run lint__config__load
  assert_success
  assert_output "{}"
}

@test "lint__config__load: rejects a config that violates the schema" {
  echo '{"indent":{"width":"two"}}' > "$BATS_TEST_TMPDIR/bad.json"

  run lint__config__load "$BATS_TEST_TMPDIR/bad.json"
  assert_failure
}

@test "lint__config__load: rejects an unknown key" {
  echo '{"excludes":["planning"]}' > "$BATS_TEST_TMPDIR/bad.json"

  run lint__config__load "$BATS_TEST_TMPDIR/bad.json"
  assert_failure
}

@test "config readers: width, tabs, test trees, excludes, added_only and disabled come from the config" {
  __config='{"indent":{"width":4,"tabs":true},"tests":["spec"],"exclude":["planning","my dir"],"added_only":["raw-jq"],"disabled":["println"]}'

  run lint__config__indent_width "$__config"
  assert_output "4"

  run lint__config__allow_tabs "$__config"
  assert_output "true"

  run lint__config__test_trees "$__config"
  assert_equal "$(@len "$output")" 1
  assert_equal "$(@get "$output" '.[0]')" "spec"

  run lint__config__excludes "$__config"
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[1]')" "my dir"

  run lint__config__added_only_checks "$__config"
  assert_equal "$(@get "$output" '.[0]')" "raw-jq"

  run lint__config__disabled_checks "$__config"
  assert_equal "$(@get "$output" '.[0]')" "println"
}

@test "config readers: defaults apply when keys are absent" {
  run lint__config__indent_width '{}'
  assert_output "2"

  run lint__config__allow_tabs '{}'
  assert_output "false"

  run lint__config__test_trees '{}'
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[0]')" "test"

  run lint__config__excludes '{}'
  assert_equal "$(@len "$output")" 0

  run lint__config__added_only_checks '{}'
  assert_equal "$(@len "$output")" 0

  run lint__config__disabled_checks '{}'
  assert_equal "$(@len "$output")" 0
}

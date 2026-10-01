#!/usr/bin/env bats
# Covers the three template checks in shell/lint/checks/templates/api.sh over the
# fixtures beside it: what they flag, what they pass over, and the facts they
# read from lint.json's templates block.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  load helpers/template_options.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/templates/declares-inputs/api.sh"
  export PROJ="$SHELL_LINT_DIR"
  FIXTURES="$SHELL_LINT_DIR/shell/lint/checks/templates"
  BASE="$FIXTURES/base.fixture.yml"
  MEMBER="$FIXTURES/member.fixture.yml"
  NO_INPUTS="$FIXTURES/no_inputs.fixture.yml"
  MARKED="$FIXTURES/marked.fixture.yml"
}

@test "lint__checks__templates__declares_inputs__run: passes templates that declare their inputs" {
  run lint__checks__templates__declares_inputs__run "$(catalog_options)" "$BASE" "$MEMBER" "$MARKED"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__declares_inputs__run: flags a template whose spec declares no inputs, on line 1" {
  run lint__checks__templates__declares_inputs__run "$(catalog_options)" "$MEMBER" "$NO_INPUTS"
  assert_failure
  assert_output --partial "no_inputs.fixture.yml:1: no spec.inputs block"
  refute_output --partial "member.fixture.yml"
}

@test "lint__checks__templates__declares_inputs__run: a template with no spec document at all is flagged" {
  __f="$(fixture jobs-only.yml <<'FIX'
"ksoft/shell/lint":
  script:
    - echo hi
FIX
)"

  run lint__checks__templates__declares_inputs__run "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "no spec.inputs block"
}

@test "lint__checks__templates__declares_inputs__run: a yaml file the pattern does not name is passed over" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'nothing/*')")")"

  run lint__checks__templates__declares_inputs__run "$__options" "$NO_INPUTS"
  assert_success
  assert_output ""
}


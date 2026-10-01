#!/usr/bin/env bats
# Covers the three template checks in shell/lint/checks/templates/api.sh over the
# fixtures beside it: what they flag, what they pass over, and the facts they
# read from lint.json's templates block.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  load helpers/template_options.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/templates/inherits-bootstrap/api.sh"
  export PROJ="$SHELL_LINT_DIR"
  FIXTURES="$SHELL_LINT_DIR/shell/lint/checks/templates"
  BASE="$FIXTURES/base.fixture.yml"
  MEMBER="$FIXTURES/member.fixture.yml"
  NO_INPUTS="$FIXTURES/no_inputs.fixture.yml"
  REDEFINES="$FIXTURES/redefines.fixture.yml"
  MARKED="$FIXTURES/marked.fixture.yml"
  UNMARKED="$FIXTURES/unmarked.fixture.yml"
}

@test "lint__checks__templates__inherits_bootstrap__run: passes a catalog whose only before_script is the base's" {
  run lint__checks__templates__inherits_bootstrap__run "$(catalog_options)" "$BASE" "$MEMBER"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__inherits_bootstrap__run: flags a member that defines a job-level before_script, naming the job" {
  run lint__checks__templates__inherits_bootstrap__run "$(catalog_options)" "$BASE" "$REDEFINES"
  assert_failure
  assert_output --partial "redefines.fixture.yml:12:"
  assert_output --partial "job '\$[[ inputs.job-name ]]' defines before_script"
  refute_output --partial "base.fixture.yml"
}

@test "lint__checks__templates__inherits_bootstrap__run: holds the base to the rule when lint.json names none" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'shell/lint/checks/templates/*.fixture.yml')")")"

  run lint__checks__templates__inherits_bootstrap__run "$__options" "$BASE"
  assert_failure
  assert_output --partial "job '.base' defines before_script"
}

@test "lint__checks__templates__inherits_bootstrap__run: a default: before_script gets the pipeline-wide charge" {
  __f="$(fixture default-override.yml <<'FIX'
spec:
  inputs:
    stage:
      default: linting
---
default:
  before_script:
    - echo hi
"$[[ inputs.job-name ]]":
  stage: $[[ inputs.stage ]]
FIX
)"

  run lint__checks__templates__inherits_bootstrap__run "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "'default:' sets before_script for every job in the pipeline"
}


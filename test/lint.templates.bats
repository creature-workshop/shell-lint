#!/usr/bin/env bats
# Covers the three template checks in shell/lint/templates/api.sh over the
# fixtures beside it: what they flag, what they pass over, and the facts they
# read from lint.json's templates block.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/templates/api.sh"
  export PROJ="$SHELL_LINT_DIR"
  FIXTURES="$SHELL_LINT_DIR/shell/lint/templates"
  BASE="$FIXTURES/base.fixture.yml"
  MEMBER="$FIXTURES/member.fixture.yml"
  NO_INPUTS="$FIXTURES/no_inputs.fixture.yml"
  REDEFINES="$FIXTURES/redefines.fixture.yml"
  MARKED="$FIXTURES/marked.fixture.yml"
  UNMARKED="$FIXTURES/unmarked.fixture.yml"
}

# Options whose templates block names the fixtures beside the module as the
# catalog: the pattern, the base, and the mark as the fixtures write it.
catalog_options() {
  __templates="$(@obj \
    '.glob' 'shell/lint/templates/*.fixture.yml' \
    '.base' 'shell/lint/templates/base.fixture.yml' \
    '.mark' 'scheduler\/next-merge'
  )"
  @obj '.config' "$(@obj '.templates' "$__templates")"
}

# Options whose pattern names every file, for a fixture written under the
# test's tmpdir, with the mark set.
any_file_options() {
  @obj '.config' "$(@obj '.templates' "$(@obj '.glob' '*' '.mark' 'scheduler\/next-merge')")"
}

@test "lint__templates__declares_inputs: passes templates that declare their inputs" {
  run lint__templates__declares_inputs "$(catalog_options)" "$BASE" "$MEMBER" "$MARKED"
  assert_success
  assert_output ""
}

@test "lint__templates__declares_inputs: flags a template whose spec declares no inputs, on line 1" {
  run lint__templates__declares_inputs "$(catalog_options)" "$MEMBER" "$NO_INPUTS"
  assert_failure
  assert_output --partial "no_inputs.fixture.yml:1: no spec.inputs block"
  refute_output --partial "member.fixture.yml"
}

@test "lint__templates__declares_inputs: a template with no spec document at all is flagged" {
  __f="$(fixture jobs-only.yml <<'FIX'
"ksoft/shell/lint":
  script:
    - echo hi
FIX
)"

  run lint__templates__declares_inputs "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "no spec.inputs block"
}

@test "lint__templates__declares_inputs: a yaml file the pattern does not name is passed over" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'nothing/*')")")"

  run lint__templates__declares_inputs "$__options" "$NO_INPUTS"
  assert_success
  assert_output ""
}

@test "lint__templates__inherits_bootstrap: passes a catalog whose only before_script is the base's" {
  run lint__templates__inherits_bootstrap "$(catalog_options)" "$BASE" "$MEMBER"
  assert_success
  assert_output ""
}

@test "lint__templates__inherits_bootstrap: flags a member that defines a job-level before_script, naming the job" {
  run lint__templates__inherits_bootstrap "$(catalog_options)" "$BASE" "$REDEFINES"
  assert_failure
  assert_output --partial "redefines.fixture.yml:12:"
  assert_output --partial "job '\$[[ inputs.job-name ]]' defines before_script"
  refute_output --partial "base.fixture.yml"
}

@test "lint__templates__inherits_bootstrap: holds the base to the rule when lint.json names none" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'shell/lint/templates/*.fixture.yml')")")"

  run lint__templates__inherits_bootstrap "$__options" "$BASE"
  assert_failure
  assert_output --partial "job '.base' defines before_script"
}

@test "lint__templates__inherits_bootstrap: a default: before_script gets the pipeline-wide charge" {
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

  run lint__templates__inherits_bootstrap "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "'default:' sets before_script for every job in the pipeline"
}

@test "lint__templates__job_lands_once: passes a check whose merge-request rule names the mark" {
  run lint__templates__job_lands_once "$(catalog_options)" "$BASE" "$MARKED"
  assert_success
  assert_output ""
}

@test "lint__templates__job_lands_once: flags a check whose merge-request rule lacks the mark, naming the job and the mark" {
  run lint__templates__job_lands_once "$(catalog_options)" "$UNMARKED"
  assert_failure
  assert_output --partial "unmarked.fixture.yml:15:"
  assert_output --partial "job '\$[[ inputs.job-name ]]' runs on every push: its rule matches merge_request_event without the mark 'scheduler\\/next-merge'"
}

@test "lint__templates__job_lands_once: a template named under every_push is exempt" {
  __templates="$(@obj \
    '.glob' 'shell/lint/templates/*.fixture.yml' \
    '.mark' 'scheduler\/next-merge' \
    '.every_push' "$(@arr shell/lint/templates/unmarked.fixture.yml)"
  )"
  __options="$(@obj '.config' "$(@obj '.templates' "$__templates")")"

  run lint__templates__job_lands_once "$__options" "$UNMARKED"
  assert_success
  assert_output ""
}

@test "lint__templates__job_lands_once: a merge-request arm withdrawn by when: never is not a finding" {
  __f="$(fixture withdrawn.yml <<'FIX'
spec:
  inputs:
    stage:
      default: linting
---
"ksoft/shell/lint":
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script:
    - echo hi
FIX
)"

  run lint__templates__job_lands_once "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__templates__job_lands_once: a folded condition is read across its lines" {
  __f="$(fixture folded.yml <<'FIX'
spec:
  inputs:
    stage:
      default: linting
---
"ksoft/shell/lint":
  rules:
    - if: >-
        $CI_PIPELINE_SOURCE == "merge_request_event"
        && $CI_MERGE_REQUEST_LABELS =~ /(^|,)scheduler\/next-merge(,|$)/
  script:
    - echo hi
FIX
)"

  run lint__templates__job_lands_once "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__templates__job_lands_once: a folded condition without the mark is a finding on the if line" {
  __f="$(fixture folded-unmarked.yml <<'FIX'
spec:
  inputs:
    stage:
      default: linting
---
"ksoft/shell/lint":
  rules:
    - if: >-
        $CI_PIPELINE_SOURCE == "merge_request_event"
        || $CI_PIPELINE_SOURCE == "web"
  script:
    - echo hi
FIX
)"

  run lint__templates__job_lands_once "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "folded-unmarked.yml:8:"
}

@test "lint__templates__job_lands_once: a rule outside a job's rules list is not judged" {
  __f="$(fixture workflow-rule.yml <<'FIX'
spec:
  inputs:
    stage:
      default: linting
---
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
"ksoft/shell/lint":
  script:
    - echo hi
FIX
)"

  run lint__templates__job_lands_once "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__templates__job_lands_once: an entry left open at a file's end is judged before the next file" {
  run lint__templates__job_lands_once "$(catalog_options)" "$UNMARKED" "$MARKED"
  assert_failure
  assert_output --partial "unmarked.fixture.yml:15:"
  refute_output --partial "/marked.fixture.yml"
}

@test "lint__templates__job_lands_once: with no mark in lint.json the check is off" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'shell/lint/templates/*.fixture.yml')")")"

  run lint__templates__job_lands_once "$__options" "$UNMARKED"
  assert_success
  assert_output ""
}

@test "lint__templates__glob: templates/*/template.yml when lint.json names no pattern" {
  run lint__templates__glob "$(@obj)"
  assert_output "templates/*/template.yml"
}

@test "lint__templates__every_push: empty when lint.json names none" {
  run lint__templates__every_push "$(@obj)"
  assert_output "$(@arr)"
}

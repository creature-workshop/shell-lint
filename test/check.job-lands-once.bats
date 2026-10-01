#!/usr/bin/env bats
# Covers the three template checks in shell/lint/checks/templates/api.sh over the
# fixtures beside it: what they flag, what they pass over, and the facts they
# read from lint.json's templates block.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  load helpers/template_options.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/templates/job-lands-once/api.sh"
  export PROJ="$SHELL_LINT_DIR"
  FIXTURES="$SHELL_LINT_DIR/shell/lint/checks/templates"
  BASE="$FIXTURES/base.fixture.yml"
  MEMBER="$FIXTURES/member.fixture.yml"
  NO_INPUTS="$FIXTURES/no_inputs.fixture.yml"
  REDEFINES="$FIXTURES/redefines.fixture.yml"
  MARKED="$FIXTURES/marked.fixture.yml"
  UNMARKED="$FIXTURES/unmarked.fixture.yml"
}

@test "lint__checks__templates__job_lands_once__run: passes a check whose merge-request rule names the mark" {
  run lint__checks__templates__job_lands_once__run "$(catalog_options)" "$BASE" "$MARKED"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__job_lands_once__run: flags a check whose merge-request rule lacks the mark, naming the job and the mark" {
  run lint__checks__templates__job_lands_once__run "$(catalog_options)" "$UNMARKED"
  assert_failure
  assert_output --partial "unmarked.fixture.yml:15:"
  assert_output --partial "job '\$[[ inputs.job-name ]]' runs on every push: its rule matches merge_request_event without the mark 'scheduler\\/next-merge'"
}

@test "lint__checks__templates__job_lands_once__run: a template named under every_push is exempt" {
  __templates="$(@obj \
    '.glob' 'shell/lint/checks/templates/*.fixture.yml' \
    '.mark' 'scheduler\/next-merge' \
    '.every_push' "$(@arr shell/lint/checks/templates/unmarked.fixture.yml)"
  )"
  __options="$(@obj '.config' "$(@obj '.templates' "$__templates")")"

  run lint__checks__templates__job_lands_once__run "$__options" "$UNMARKED"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__job_lands_once__run: a merge-request arm withdrawn by when: never is not a finding" {
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

  run lint__checks__templates__job_lands_once__run "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__job_lands_once__run: a folded condition is read across its lines" {
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

  run lint__checks__templates__job_lands_once__run "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__job_lands_once__run: a folded condition without the mark is a finding on the if line" {
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

  run lint__checks__templates__job_lands_once__run "$(any_file_options)" "$__f"
  assert_failure
  assert_output --partial "folded-unmarked.yml:8:"
}

@test "lint__checks__templates__job_lands_once__run: a rule outside a job's rules list is not judged" {
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

  run lint__checks__templates__job_lands_once__run "$(any_file_options)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__templates__job_lands_once__run: an entry left open at a file's end is judged before the next file" {
  run lint__checks__templates__job_lands_once__run "$(catalog_options)" "$UNMARKED" "$MARKED"
  assert_failure
  assert_output --partial "unmarked.fixture.yml:15:"
  refute_output --partial "/marked.fixture.yml"
}

@test "lint__checks__templates__job_lands_once__run: with no mark in lint.json the check is off" {
  __options="$(@obj '.config' "$(@obj '.templates' "$(@obj '.glob' 'shell/lint/checks/templates/*.fixture.yml')")")"

  run lint__checks__templates__job_lands_once__run "$__options" "$UNMARKED"
  assert_success
  assert_output ""
}


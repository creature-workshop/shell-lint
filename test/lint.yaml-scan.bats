#!/usr/bin/env bats
# Covers yaml_scan.awk's block model where the scanners on it cannot see it:
# what a line is read as, and where a key sits. The probe fixture prints the
# model's reading of each record.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  LINT="$SHELL_LINT_DIR/shell/lint"
  PROBE="$SHELL_LINT_DIR/test/fixtures/lint/yaml_scan_probe.awk"
}

# The model's reading of one file, one line per record it classifies.
scan() {
  awk -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" -f "$LINT/lib/yaml_scan.awk" -f "$PROBE" "$1"
}

@test "yaml_scan: a key beside a leaf key in the same sequence entry is a key, not the leaf's content" {
  __f="$(fixture rule.yml <<'FIX'
job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
FIX
)"

  run scan "$__f"
  assert_success
  assert_line "3: key if depth=3 parent="
  assert_line "4: key when depth=3 parent="
}

@test "yaml_scan: a block scalar's lines are its key's content" {
  __f="$(fixture folded.yml <<'FIX'
job:
  rules:
    - if: >-
        $CI_PIPELINE_SOURCE == "merge_request_event"
        || $CI_PIPELINE_SOURCE == "web"
      when: always
FIX
)"

  run scan "$__f"
  assert_success
  assert_line "3: key if depth=3 parent="
  assert_line "4: content"
  assert_line "5: content"
  assert_line "6: key when depth=3 parent="
}

@test "yaml_scan: a plain scalar continued deeper than its key is content" {
  __f="$(fixture continued.yml <<'FIX'
job:
  script:
    - name: a value that
        continues on the next line
    - echo done
FIX
)"

  run scan "$__f"
  assert_success
  assert_line "3: key name depth=3 parent="
  assert_line "4: content"
  assert_line "5: scalar"
}

@test "yaml_scan: a leaf key at the top of a mapping does not swallow its siblings" {
  __f="$(fixture siblings.yml <<'FIX'
job:
  stage: linting
  script:
    - echo hi
FIX
)"

  run scan "$__f"
  assert_success
  assert_line "2: key stage depth=1 parent=job"
  assert_line "3: key script depth=1 parent=job"
}

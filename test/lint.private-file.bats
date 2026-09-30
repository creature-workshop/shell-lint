#!/usr/bin/env bats
# Covers shell/lint/private_file.awk through lint__private_file: a file only
# its own module imports is named with a leading _.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/_private_file.sh"

  ROOT="$TEST_DIR/fixtures/lint/private-file"

  # The fixtures under lib/ are shellops-shaped, and lib/ is a library root
  # only when the options name it, as shellops' own lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "lint__private_file: a private file named without a leading _ is a finding" {
  run lint__private_file "$SHELLOPS_ROOTS" \
    "$ROOT/lib/testing/trace/api.sh" \
    "$ROOT/lib/testing/trace/_tracer.sh" \
    "$ROOT/lib/testing/trace/location.sh" \
    "$ROOT/lib/testing/trace/kept.sh" \
    "$ROOT/lib/other/api.sh" \
    "$ROOT/cli/consumer.sh"

  assert_failure
  assert_output --partial "location.sh:1: private file location.sh belongs to lib/testing/trace; its name begins with _"
  refute_output --partial "_tracer.sh:"
  refute_output --partial "kept.sh:"
  refute_output --partial "trace/api.sh:"
  refute_output --partial "other/api.sh:"
  refute_output --partial "consumer.sh:"
}

# A consumer's checkout: the fixtures copied outside shellops, so PROJ does
# not stand in SHELLOPS_DIR and the consumer's default roots apply.
consumer() {
  cp -a "$ROOT" "$BATS_TEST_TMPDIR/consumer"
  printf '%s\n' "$BATS_TEST_TMPDIR/consumer"
}

@test "lint__private_file: a consumer's module under its shell home is judged, its imports spelled from PROJ" {
  __c="$(consumer)"

  PROJ="$__c" run lint__private_file "$(@obj)" \
    "$__c/shell/demo/api.sh" \
    "$__c/shell/demo/location.sh"

  assert_failure
  assert_output --partial "location.sh:1: private file location.sh belongs to shell/demo; its name begins with _"

  PROJ="$__c" run lint__private_file "$(@obj)" \
    "$__c/src/demo/api.sh" \
    "$__c/src/demo/location.sh"

  assert_failure
  assert_output --partial "location.sh:1: private file location.sh belongs to src/demo; its name begins with _"
}

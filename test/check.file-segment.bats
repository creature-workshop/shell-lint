#!/usr/bin/env bats
# Covers shell/lint/checks/shell/file-segment/file_segment.awk through
# lint__checks__shell__file_segment__run: a name in a library file spells
# the file's stem as a segment of its own.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/file-segment/api.sh"

  ROOT="$TEST_DIR/fixtures/lint/file-segment"

  # The fixtures under lib/ are shellops-shaped, and lib/ is a library root
  # only when the options name it, as shellops' own lint.json does.
  @arr __setup__arr_1 lib interpreter
  @obj __setup__obj_2 '.library_roots' "$__setup__arr_1"
  @obj SHELLOPS_ROOTS '.config' "$__setup__obj_2"
}

@test "lint__checks__shell__file_segment__run: a public name, a private name and a variable that spell the stem with one underscore are findings, and a function's variables are judged through the function" {
  run lint__checks__shell__file_segment__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/trace/latest.sh"

  assert_failure
  assert_output --partial "latest.sh:1: name testing__trace__latest_read spells latest, its file, with one underscore; the file is a segment, so the name begins testing__trace__latest__"
  refute_output --partial "latest.sh:2:"
  refute_output --partial "latest.sh:3:"
  assert_output --partial "latest.sh:19: name __testing__trace__latest_total spells latest, its file, with one underscore"
  refute_output --partial "latest.sh:20:"
  refute_output --partial "latest.sh:21:"
  refute_output --partial "latest.sh:6:"
  refute_output --partial "latest.sh:7:"
  refute_output --partial "latest.sh:8:"
  refute_output --partial "latest.sh:11:"
  refute_output --partial "latest.sh:13:"
  refute_output --partial "latest.sh:15:"
  refute_output --partial "latest.sh:17:"
  refute_output --partial "latest.sh:18:"
}

@test "lint__checks__shell__file_segment__run: the barrel, a plugin and a file at a library root have no stem to judge" {
  run lint__checks__shell__file_segment__run "$SHELLOPS_ROOTS" \
    "$ROOT/lib/testing/trace/api.sh" \
    "$ROOT/lib/testing/trace/latest.check.op.sh" \
    "$ROOT/lib/trace.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__file_segment__run: an entrypoint carries no module path" {
  @obj at3
  run lint__checks__shell__file_segment__run "$at3" "$ROOT/cli/main.sh"

  assert_success
  assert_output ""
}

# A consumer's checkout: the fixtures copied outside shellops, so PROJ does
# not stand in SHELLOPS_DIR and the consumer's default roots apply.
consumer() {
  cp -a "$ROOT" "$BATS_TEST_TMPDIR/consumer"
  printf '%s\n' "$BATS_TEST_TMPDIR/consumer"
}

@test "lint__checks__shell__file_segment__run: a consumer's module under its shell home is judged by its path under that root" {
  __c="$(consumer)"

  @obj at4
  PROJ="$__c" run lint__checks__shell__file_segment__run "$at4" "$__c/shell/demo/latest.sh"

  assert_failure
  assert_output --partial "latest.sh:1: name demo__latest_read spells latest, its file, with one underscore; the file is a segment, so the name begins demo__latest__"
  refute_output --partial "latest.sh:2:"
}

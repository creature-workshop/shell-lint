#!/usr/bin/env bats
# Covers shell/lint/public_name.awk through lint__checks__shell__public_name__run: a public name
# begins with its file's module path.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/public-name/api.sh"

  ROOT="$TEST_DIR/fixtures/lint/public-name"

  # The fixtures under lib/ are shellops-shaped, and lib/ is a library root
  # only when the options name it, as shellops' own lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "lint__checks__shell__public_name__run: a public name that skips its module path is a finding" {
  run lint__checks__shell__public_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/selectors/areas/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: public name testing_selectors_areas_attach does not begin with testing__selectors__areas__"
  assert_output --partial "short.sh:9: public name testing__selectors__areas__api__attach spells api, the module's own file, as a segment"
  refute_output --partial "short.sh:5:"
}

@test "lint__checks__shell__public_name__run: a call of another module's public name is clean" {
  run lint__checks__shell__public_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/selectors/trace/caller.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__public_name__run: an entrypoint carries no module path" {
  run lint__checks__shell__public_name__run "$(@obj)" "$ROOT/cli/main.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__public_name__run: a heredoc, an allow mark and an owned enum are clean" {
  run lint__checks__shell__public_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/trace/held.sh"

  assert_failure
  assert_output --partial "held.sh:14: public name TRACE_LEVEL does not begin with testing__trace__"
  refute_output --partial "held.sh:2:"
  refute_output --partial "held.sh:5:"
  refute_output --partial "held.sh:9:"
  refute_output --partial "held.sh:13:"
}

# A consumer's checkout: the fixtures copied outside shellops, so PROJ does
# not stand in SHELLOPS_DIR and the consumer's default roots apply.
consumer() {
  cp -a "$ROOT" "$BATS_TEST_TMPDIR/consumer"
  printf '%s\n' "$BATS_TEST_TMPDIR/consumer"
}

@test "lint__checks__shell__public_name__run: a consumer's module under its shell home carries its path under that root" {
  __c="$(consumer)"

  PROJ="$__c" run lint__checks__shell__public_name__run "$(@obj)" "$__c/shell/demo/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: public name demo_attach does not begin with demo__"

  PROJ="$__c" run lint__checks__shell__public_name__run "$(@obj)" "$__c/src/demo/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: public name demo_attach does not begin with demo__"
}

@test "lint__checks__shell__public_name__run: a consumer's root lib/ is its product's, unjudged until library_roots names it" {
  __c="$(consumer)"

  PROJ="$__c" run lint__checks__shell__public_name__run "$(@obj)" "$__c/lib/testing/selectors/areas/short.sh"

  assert_success
  assert_output ""

  PROJ="$__c" run lint__checks__shell__public_name__run "$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib)")")" "$__c/lib/testing/selectors/areas/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: public name testing_selectors_areas_attach does not begin with testing__selectors__areas__"
}

@test "lint__checks__shell__public_name__run: lint.json's library_roots replace the defaults, so a configured root is judged and a default one is not" {
  __c="$(consumer)"
  __opts="$(@obj '.config' "$(@obj '.library_roots' "$(@arr tools)")")"

  PROJ="$__c" run lint__checks__shell__public_name__run "$__opts" "$__c/tools/demo/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: public name demo_attach does not begin with demo__"

  PROJ="$__c" run lint__checks__shell__public_name__run "$__opts" "$__c/src/demo/short.sh"

  assert_success
  assert_output ""
}

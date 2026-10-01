#!/usr/bin/env bats
# Covers shell/lint/private_name.awk through lint__checks__shell__private_name__run: a private name
# begins with its file's module path.

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/private-name/api.sh"

  ROOT="$TEST_DIR/fixtures/lint/private-name"

  # The fixtures under lib/ are shellops-shaped, and lib/ is a library root
  # only when the options name it, as shellops' own lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "lint__checks__shell__private_name__run: a private name that skips its module path is a finding" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/selectors/areas/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: private name __areas__REACHING does not begin with __testing__selectors__areas__"
  refute_output --partial "short.sh:2:"
}

@test "lint__checks__shell__private_name__run: a caller spelling another module's private name is a finding" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/selectors/trace/caller.sh"

  assert_failure
  assert_output --partial "caller.sh:3: private name __testing__trace__read does not begin with __testing__selectors__trace__"
  refute_output --partial "caller.sh:2:"
}

@test "lint__checks__shell__private_name__run: a role's bindings and the module's own names are clean" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/selectors/areas/plugin.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__private_name__run: an entrypoint carries no module path" {
  run lint__checks__shell__private_name__run "$(@obj)" "$ROOT/cli/main.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__private_name__run: a heredoc, an allowed line and every binding word are clean" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/trace/held.sh"

  assert_success
  assert_output ""
}

@test "lint__checks__shell__private_name__run: a function's variables are fully qualified, and api is no segment" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/trace/variables.sh"

  assert_failure
  assert_output --partial "variables.sh:3: variable __trace_latest__map is assigned in testing__trace__latest, whose variables begin with __testing__trace__latest__"
  assert_output --partial "variables.sh:1: the variables of testing__trace__latest begin with __testing__trace__latest__; __trace_latest__map does not"
  assert_output --partial "variables.sh:9: private name __other_fn__x is read in testing_trace_read_map and is not the module's"
  assert_output --partial "variables.sh:11: private name __testing__trace__api__helper spells api, the module's own file, as a segment"
  refute_output --partial "variables.sh:2:"
  refute_output --partial "variables.sh:4:"
  refute_output --partial "variables.sh:6:"
  refute_output --partial "variables.sh:7:"
  refute_output --partial "variables.sh:8:"
  refute_output --partial "variables.sh:12:"
  refute_output --partial "variables.sh:13:"
  refute_output --partial "variables.sh:14:"
  refute_output --partial "variables.sh:15:"
  refute_output --partial "__testing__trace__read_map__"
  refute_output --partial "__testing__trace__CACHE"
}

@test "lint__checks__shell__private_name__run: a child spells its parents' private names, not a sibling's" {
  run lint__checks__shell__private_name__run "$SHELLOPS_ROOTS" "$ROOT/lib/testing/trace/inner/child.sh"

  assert_failure
  assert_output --partial "child.sh:4: private name __testing__selectors__areas__attach does not begin with __testing__trace__inner__"
  refute_output --partial "child.sh:2:"
  refute_output --partial "child.sh:3:"
  refute_output --partial "child.sh:7:"
}

# A consumer's checkout: the fixtures copied outside shellops, so PROJ does
# not stand in SHELLOPS_DIR and the consumer's default roots apply.
consumer() {
  cp -a "$ROOT" "$BATS_TEST_TMPDIR/consumer"
  printf '%s\n' "$BATS_TEST_TMPDIR/consumer"
}

@test "lint__checks__shell__private_name__run: a consumer's module under its shell home carries its path under that root" {
  __c="$(consumer)"

  PROJ="$__c" run lint__checks__shell__private_name__run "$(@obj)" "$__c/shell/demo/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: private name __areas__REACHING does not begin with __demo__"

  PROJ="$__c" run lint__checks__shell__private_name__run "$(@obj)" "$__c/scripts/demo/short.sh"

  assert_failure
  assert_output --partial "short.sh:1: private name __areas__REACHING does not begin with __demo__"
}

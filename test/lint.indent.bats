#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/api.sh"
  CLEAN_FIXTURE="$SHELL_LINT_DIR/test/fixtures/indent/clean.sh"
}

@test "lint__indent: accepts a clean fixture (exploded \$() form + heredoc prose)" {
  run lint__indent "$(@obj)" "$CLEAN_FIXTURE"
  assert_success
  assert_output ""
}

@test "lint__indent: accepts the exploded \$( ... ) one-arg-per-line form" {
  __fixture="$BATS_TEST_TMPDIR/exploded.sh"
  cat > "$__fixture" <<'FIX'
collect() {
  __collect__out="$(printf '%s\n' \
    "one" \
    "two" \
  )"
  printf '%s' "$__collect__out"
}
FIX

  run lint__indent "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__indent: ignores odd indentation inside a heredoc body" {
  __fixture="$BATS_TEST_TMPDIR/heredoc.sh"
  cat > "$__fixture" <<'FIX'
main() {
  cat <<EOF
   three-space prose line inside a heredoc body
     five-space prose line
EOF
}
FIX

  run lint__indent "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__indent: flags a hard tab in indentation" {
  __fixture="$BATS_TEST_TMPDIR/tabbed.sh"
  printf 'main() {\n\techo hi\n}\n' > "$__fixture"

  run lint__indent "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "tab in indentation"
}

@test "lint__indent: flags an odd (non-multiple-of-2) leading-space run" {
  __fixture="$BATS_TEST_TMPDIR/odd.sh"
  printf 'main() {\n   echo hi\n}\n' > "$__fixture"

  run lint__indent "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "not a multiple of 2"
}

@test "lint__indent: flags trailing whitespace" {
  __fixture="$BATS_TEST_TMPDIR/trailing.sh"
  printf 'echo hi \n' > "$__fixture"

  run lint__indent "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "trailing whitespace"
}

@test "lint__indent: anchors a violation to its file and line number" {
  __fixture="$BATS_TEST_TMPDIR/anchored.sh"
  printf 'a=1\n   b=2\n' > "$__fixture"

  run lint__indent "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "anchored.sh:2:"
}

@test "lint__indent: the width argument sets the required leading-space multiple" {
  __fixture="$BATS_TEST_TMPDIR/width.sh"
  printf 'main() {\n  echo hi\n}\n' > "$__fixture"

  run lint__indent "$(@obj '.config.indent.width' 4)" "$__fixture"
  assert_failure
  assert_output --partial "not a multiple of 4"
}

@test "lint__indent: allow_tabs=1 permits leading tabs" {
  __fixture="$BATS_TEST_TMPDIR/tabs-ok.sh"
  printf 'main() {\n\techo hi\n}\n' > "$__fixture"

  run lint__indent "$(@obj '.config.indent.tabs' true)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__indent: one run over many files names every file's finding" {
  __one="$BATS_TEST_TMPDIR/one.sh"
  __two="$BATS_TEST_TMPDIR/two.sh"
  printf 'main() {\n   echo one\n}\n' > "$__one"
  printf 'main() {\n  echo ok\n     echo two\n}\n' > "$__two"

  run lint__indent "$(@obj)" "$__one" "$BATS_TEST_TMPDIR/missing.sh" "$__two"
  assert_failure
  assert_output --partial "one.sh:2:"
  assert_output --partial "two.sh:3:"
  refute_output --partial "missing.sh"
}

@test "lint__call_with_existing: no existing file means nothing is called, so no awk waits on stdin" {
  called() { echo "called with $#"; }
  run lint__call_with_existing called "$BATS_TEST_TMPDIR/missing.sh" "$BATS_TEST_TMPDIR/also-missing.sh"
  assert_success
  assert_output ""
}

#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/indent/api.sh"
  CLEAN_FIXTURE="$SHELL_LINT_DIR/test/fixtures/indent/clean.sh"
}

@test "lint__checks__shell__indent__run: accepts a clean fixture (exploded \$() form + heredoc prose)" {
  @obj at1
  run lint__checks__shell__indent__run "$at1" "$CLEAN_FIXTURE"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__indent__run: accepts the exploded \$( ... ) one-arg-per-line form" {
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

  @obj at2
  run lint__checks__shell__indent__run "$at2" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__indent__run: ignores odd indentation inside a heredoc body" {
  __fixture="$BATS_TEST_TMPDIR/heredoc.sh"
  cat > "$__fixture" <<'FIX'
main() {
  cat <<EOF
   three-space prose line inside a heredoc body
     five-space prose line
EOF
}
FIX

  @obj at3
  run lint__checks__shell__indent__run "$at3" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__indent__run: flags a hard tab in indentation" {
  __fixture="$BATS_TEST_TMPDIR/tabbed.sh"
  printf 'main() {\n\techo hi\n}\n' > "$__fixture"

  @obj at4
  run lint__checks__shell__indent__run "$at4" "$__fixture"
  assert_failure
  assert_output --partial "tab in indentation"
}

@test "lint__checks__shell__indent__run: flags an odd (non-multiple-of-2) leading-space run" {
  __fixture="$BATS_TEST_TMPDIR/odd.sh"
  printf 'main() {\n   echo hi\n}\n' > "$__fixture"

  @obj at5
  run lint__checks__shell__indent__run "$at5" "$__fixture"
  assert_failure
  assert_output --partial "not a multiple of 2"
}

@test "lint__checks__shell__indent__run: flags trailing whitespace" {
  __fixture="$BATS_TEST_TMPDIR/trailing.sh"
  printf 'echo hi \n' > "$__fixture"

  @obj at6
  run lint__checks__shell__indent__run "$at6" "$__fixture"
  assert_failure
  assert_output --partial "trailing whitespace"
}

@test "lint__checks__shell__indent__run: anchors a violation to its file and line number" {
  __fixture="$BATS_TEST_TMPDIR/anchored.sh"
  printf 'a=1\n   b=2\n' > "$__fixture"

  @obj at7
  run lint__checks__shell__indent__run "$at7" "$__fixture"
  assert_failure
  assert_output --partial "anchored.sh:2:"
}

@test "lint__checks__shell__indent__run: the width argument sets the required leading-space multiple" {
  __fixture="$BATS_TEST_TMPDIR/width.sh"
  printf 'main() {\n  echo hi\n}\n' > "$__fixture"

  @obj at8 '.config.indent.width' 4
  run lint__checks__shell__indent__run "$at8" "$__fixture"
  assert_failure
  assert_output --partial "not a multiple of 4"
}

@test "lint__checks__shell__indent__run: allow_tabs=1 permits leading tabs" {
  __fixture="$BATS_TEST_TMPDIR/tabs-ok.sh"
  printf 'main() {\n\techo hi\n}\n' > "$__fixture"

  @obj at9 '.config.indent.tabs' true
  run lint__checks__shell__indent__run "$at9" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__indent__run: one run over many files names every file's finding" {
  __one="$BATS_TEST_TMPDIR/one.sh"
  __two="$BATS_TEST_TMPDIR/two.sh"
  printf 'main() {\n   echo one\n}\n' > "$__one"
  printf 'main() {\n  echo ok\n     echo two\n}\n' > "$__two"

  @obj at10
  run lint__checks__shell__indent__run "$at10" "$__one" "$BATS_TEST_TMPDIR/missing.sh" "$__two"
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

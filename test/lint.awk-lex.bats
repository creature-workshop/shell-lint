#!/usr/bin/env bats
# Covers shell/lint/awk_lex.awk: which characters of awk source are code, which
# sit in a string or regex, and which in a comment. The driver beside the
# sample marks a literal's characters L and a comment's C.

setup() {
  load helpers/setup.bash

  FIXTURES="$TEST_DIR/fixtures/lint"
}

classes() {
  awk \
    -f "$SHELL_LINT_DIR/shell/lint/lib/awk_lex.awk" \
    -f "$FIXTURES/awk_lex_classes.awk" \
    "$FIXTURES/awk_lex.fixture.awk"
}

@test "awk_lex_char: the sample's strings, regexes and comments are classed as the expected file has them" {
  run classes

  assert_success
  assert_output "$(cat "$FIXTURES/awk_lex.fixture.expected.txt")"
}

@test "awk_lex_char: a # inside a string or a regex opens no comment" {
  run classes

  assert_line --index 0 'x = LLLLLLL CCCCCC'
  assert_line --index 2 'if (line ~ LLLLLL) { n++ }'
  assert_line --index 4 'name = LLLLLLLLLLLLLLLLL'
}

@test "awk_lex_char: a slash divides after an identifier or a closed string" {
  run classes

  assert_line --index 1 'y = a / b / c'
  assert_line --index 3 'z = LLL / 2 CCC'
}

@test "awk_lex_char: a slash opens a regex at the start of a line, whatever the line above ended on" {
  run classes

  assert_line --index 6 'LLLLL { next }'
}

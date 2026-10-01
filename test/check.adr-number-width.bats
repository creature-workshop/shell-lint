#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/number-width/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__checks__adrs__number_width__run: passes a record whose number has six digits" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__checks__adrs__number_width__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__number_width__run: flags a record padded to four digits, saying the number it should carry" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 0007-fragments one_page)"

  run lint__checks__adrs__number_width__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_output "$__record:1: the record's number is written with 6 digits: 000007"
}

@test "lint__checks__adrs__number_width__run: holds a record to the width lint.json sets" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 0007-fragments one_page)"

  __opts="$(@set "$ONE_PAGE" '.config.decisions.number_digits' 4)"

  run lint__checks__adrs__number_width__run "$__opts" "$__record"
  assert_success
  assert_output ""
}


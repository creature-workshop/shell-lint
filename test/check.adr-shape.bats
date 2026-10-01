#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/shape/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__checks__adrs__shape__run: passes a record that keeps the one-page shape" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__checks__adrs__shape__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__shape__run: flags a title carrying another number, a missing header line and sections out of order" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-misshapen misshapen)"

  run lint__checks__adrs__shape__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:1: the title is \"# ADR.7: <the decision>\", the record's number"
  assert_line "$__record:1: the header has no \"- Date:\" line"
  assert_line "$__record:1: the sections are Context, Decision, Consequences, in that order"
}

@test "lint__checks__adrs__shape__run: passes every file in a repository that names no form" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-misshapen misshapen)"

  run lint__checks__adrs__shape__run "$(@obj '.config.decisions.folder' adrs)" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__shape__run: passes over the template and markdown outside the folder" {
  __template="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs template misshapen)"
  __elsewhere="$(lint__checks__adrs__fixture_one_page "$PROJ" notes 000007-misshapen misshapen)"

  run lint__checks__adrs__shape__run "$ONE_PAGE" "$__template" "$__elsewhere"
  assert_success
  assert_output ""
}


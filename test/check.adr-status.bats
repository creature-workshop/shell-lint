#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/status/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  @obj ONE_PAGE \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
}

@test "lint__checks__adrs__status__run: passes a record that is approved, and one that names the record that superseded it" {
  __approved="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __superseded="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000008-an-earlier-one superseded)"

  run lint__checks__adrs__status__run "$ONE_PAGE" "$__approved" "$__superseded"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__status__run: flags a record that still says proposed, on its Status line" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments unapproved)"

  run lint__checks__adrs__status__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_output "$__record:3: the status is \"approved\", or \"superseded by\" and a link to the ADR that did"
}

@test "lint__checks__adrs__status__run: passes every file in a repository that names no form" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments unapproved)"

  @obj at1 '.config.decisions.folder' adrs
  run lint__checks__adrs__status__run "$at1" "$__record"
  assert_success
  assert_output ""
}


#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/page/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  @obj ONE_PAGE \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
}

@test "lint__checks__adrs__page__run: passes a record within the default page, its fence and figure line free" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__checks__adrs__page__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__page__run: flags a record past the page lint.json sets, saying both counts" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  @set __opts "$ONE_PAGE" '.config.decisions.page_words' 20

  run lint__checks__adrs__page__run "$__opts" "$__record"
  assert_failure
  assert_output "$__record:1: 41 words of prose; a page is 20"
}


@test "lint__checks__adrs__page__run: counts each record from its own Context heading when it reads many in one run" {
  __first="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __second="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000008-an-earlier-one superseded)"
  __third="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments-again one_page)"
  @set __opts "$ONE_PAGE" '.config.decisions.page_words' 20

  run lint__checks__adrs__page__run "$__opts" "$__first" "$__second" "$__third"
  assert_failure
  assert_output "$__first:1: 41 words of prose; a page is 20
$__second:1: 41 words of prose; a page is 20
$__third:1: 41 words of prose; a page is 20"
}

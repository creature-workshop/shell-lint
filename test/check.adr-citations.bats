#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/citations/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  @obj ONE_PAGE \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
}

@test "lint__checks__adrs__citations__run: passes a linked citation and a bare one inside a fenced example" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__checks__adrs__citations__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__citations__run: flags an unlinked citation and one spelled the old way, each on its line" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-loose loose_citations)"

  run lint__checks__adrs__citations__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:9: link the citation: ADR.3@tool"
  assert_line "$__record:13: cite as ADR.<n>@<repository>: tool ADR 4"
}


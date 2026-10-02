#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/table-shape/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__checks__adrs__table_shape__run: passes a table file that keeps the shape" {
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table)"

  run lint__checks__adrs__table_shape__run "$ONE_PAGE" "$__table"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__table_shape__run: flags a file with no H1, a summary under a quarter of the page, and no glossary" {
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds bare_table)"

  run lint__checks__adrs__table_shape__run "$ONE_PAGE" "$__table"
  assert_failure
  assert_line "$__table:1: the title is an H1: \"# <the table's title>\""
  assert_line "$__table:1: the summary is 16 words; a quarter to half of the page is 112 to 225"
  assert_line "$__table:1: the summary is followed by a \"## Glossary\" section"
}

@test "lint__checks__adrs__table_shape__run: flags a second table after the glossary, on its first row" {
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds two_tables)"

  run lint__checks__adrs__table_shape__run "$ONE_PAGE" "$__table"
  assert_failure
  assert_output "$__table:25: the glossary is followed by one table"
}

@test "lint__checks__adrs__table_shape__run: holds the summary to a quarter to half of the page lint.json sets" {
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table)"
  __opts="$(@set "$ONE_PAGE" '.config.decisions.page_words' 40)"

  run lint__checks__adrs__table_shape__run "$__opts" "$__table"
  assert_failure
  assert_output "$__table:1: the summary is 125 words; a quarter to half of the page is 10 to 20"
}

@test "lint__checks__adrs__table_shape__run: passes over the record beside the table and markdown outside the folder" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __elsewhere="$(lint__checks__adrs__fixture_table "$PROJ" notes 000007-fragments kinds bare_table)"

  run lint__checks__adrs__table_shape__run "$ONE_PAGE" "$__record" "$__elsewhere"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__table_shape__run: passes every file in a repository that names no form" {
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds bare_table)"

  run lint__checks__adrs__table_shape__run "$(@obj '.config.decisions.folder' adrs)" "$__table"
  assert_success
  assert_output ""
}


@test "lint__checks__adrs__table_shape__run: reads many table files in one run and judges each on its own" {
  __kept="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table)"
  __bare="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments costs bare_table)"
  __doubled="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000008-later kinds two_tables)"

  run lint__checks__adrs__table_shape__run "$ONE_PAGE" "$__kept" "$__bare" "$__doubled"
  assert_failure
  assert_line "$__bare:1: the title is an H1: \"# <the table's title>\""
  assert_line "$__bare:1: the summary is followed by a \"## Glossary\" section"
  assert_line "$__doubled:25: the glossary is followed by one table"
  refute_line --partial "$__kept:"
}

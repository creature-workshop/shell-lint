#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/decisions/_tables.sh"
  source "$SHELL_LINT_DIR/shell/lint/decisions/fixtures.sh"
  PROJ="$(lint__decisions__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__decisions__tables__shape: passes a table file that keeps the shape" {
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table)"

  run lint__decisions__tables__shape "$ONE_PAGE" "$__table"
  assert_success
  assert_output ""
}

@test "lint__decisions__tables__shape: flags a file with no H1, a summary under a quarter of the page, and no glossary" {
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds bare_table)"

  run lint__decisions__tables__shape "$ONE_PAGE" "$__table"
  assert_failure
  assert_line "$__table:1: the title is an H1: \"# <the table's title>\""
  assert_line "$__table:1: the summary is 16 words; a quarter to half of the page is 112 to 225"
  assert_line "$__table:1: the summary is followed by a \"## Glossary\" section"
}

@test "lint__decisions__tables__shape: flags a second table after the glossary, on its first row" {
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds two_tables)"

  run lint__decisions__tables__shape "$ONE_PAGE" "$__table"
  assert_failure
  assert_output "$__table:25: the glossary is followed by one table"
}

@test "lint__decisions__tables__shape: holds the summary to a quarter to half of the page lint.json sets" {
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table)"
  __opts="$(@set "$ONE_PAGE" '.config.decisions.page_words' 40)"

  run lint__decisions__tables__shape "$__opts" "$__table"
  assert_failure
  assert_output "$__table:1: the summary is 125 words; a quarter to half of the page is 10 to 20"
}

@test "lint__decisions__tables__shape: passes over the record beside the table and markdown outside the folder" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __elsewhere="$(lint__decisions__fixture_table "$PROJ" notes 000007-fragments kinds bare_table)"

  run lint__decisions__tables__shape "$ONE_PAGE" "$__record" "$__elsewhere"
  assert_success
  assert_output ""
}

@test "lint__decisions__tables__shape: passes every file in a repository that names no form" {
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds bare_table)"

  run lint__decisions__tables__shape "$(@obj '.config.decisions.folder' adrs)" "$__table"
  assert_success
  assert_output ""
}

@test "lint__decisions__tables__reference: passes a record that links its table by its title" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments with_table)"
  lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__decisions__tables__reference "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__tables__reference: flags the table a record never links, and the one it keeps in a fence" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__decisions__tables__reference "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:18: a table is a figure: move it to tables/<name>.md and reference it as [Table <k>: <title>](tables/<name>.md)"
  assert_line "$__record:1: the record references its table: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__decisions__tables__reference: flags a link whose text is not the table's title or not in the Table form, and a link to no table" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments mistitled_table)"
  lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__decisions__tables__reference "$ONE_PAGE" "$__record"
  assert_failure
  assert_equal "${#lines[@]}" 3
  assert_line "$__record:15: the link's text is \"Table <k>: \" and the table's title: [Table 1: The kinds of change a label names](tables/kinds.md)"
  assert_line "$__record:16: no table is at tables/counters.md"
  assert_line "$__record:17: the link's text is \"Table <k>: \" and the table's title: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__decisions__tables__reference: checks the record beside a table file named on its own, once" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  __table="$(lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table)"

  run lint__decisions__tables__reference "$ONE_PAGE" "$__table" "$__record"
  assert_failure
  assert_equal "${#lines[@]}" 2
  assert_line "$__record:1: the record references its table: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__decisions__tables__reference: passes a record with no tables directory" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__decisions__tables__reference "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__tables__reference: passes every file in a repository that names no form" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  lint__decisions__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__decisions__tables__reference "$(@obj '.config.decisions.folder' adrs)" "$__record"
  assert_success
  assert_output ""
}

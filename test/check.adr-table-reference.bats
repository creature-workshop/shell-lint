#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/table-reference/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__checks__adrs__table_reference__run: passes a record that links its table by its title" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments with_table)"
  lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__checks__adrs__table_reference__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__table_reference__run: flags the table a record never links, and the one it keeps in a fence" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__checks__adrs__table_reference__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:18: a table is a figure: move it to tables/<name>.md and reference it as [Table <k>: <title>](tables/<name>.md)"
  assert_line "$__record:1: the record references its table: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__checks__adrs__table_reference__run: flags a link whose text is not the table's title or not in the Table form, and a link to no table" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments mistitled_table)"
  lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__checks__adrs__table_reference__run "$ONE_PAGE" "$__record"
  assert_failure
  assert_equal "${#lines[@]}" 3
  assert_line "$__record:15: the link's text is \"Table <k>: \" and the table's title: [Table 1: The kinds of change a label names](tables/kinds.md)"
  assert_line "$__record:16: no table is at tables/counters.md"
  assert_line "$__record:17: the link's text is \"Table <k>: \" and the table's title: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__checks__adrs__table_reference__run: checks the record beside a table file named on its own, once" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  __table="$(lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table)"

  run lint__checks__adrs__table_reference__run "$ONE_PAGE" "$__table" "$__record"
  assert_failure
  assert_equal "${#lines[@]}" 2
  assert_line "$__record:1: the record references its table: [Table <k>: The kinds of change a label names](tables/kinds.md)"
}

@test "lint__checks__adrs__table_reference__run: passes a record with no tables directory" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__checks__adrs__table_reference__run "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__table_reference__run: passes every file in a repository that names no form" {
  __record="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments fenced_table)"
  lint__checks__adrs__fixture_table "$PROJ" adrs 000007-fragments kinds table >/dev/null

  run lint__checks__adrs__table_reference__run "$(@obj '.config.decisions.folder' adrs)" "$__record"
  assert_success
  assert_output ""
}

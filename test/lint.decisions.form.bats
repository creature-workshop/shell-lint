#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/decisions/form.sh"
  source "$SHELL_LINT_DIR/shell/lint/decisions/fixtures.sh"
  PROJ="$(lint__decisions__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__decisions__form__shape: passes a record that keeps the one-page shape" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__decisions__form__shape "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__shape: flags a title carrying another number, a missing header line and sections out of order" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-misshapen misshapen)"

  run lint__decisions__form__shape "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:1: the title is \"# ADR.7: <the decision>\", the record's number"
  assert_line "$__record:1: the header has no \"- Date:\" line"
  assert_line "$__record:1: the sections are Context, Decision, Consequences, in that order"
}

@test "lint__decisions__form__shape: passes every file in a repository that names no form" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-misshapen misshapen)"

  run lint__decisions__form__shape "$(@obj '.config.decisions.folder' adrs)" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__shape: passes over the template and markdown outside the folder" {
  __template="$(lint__decisions__fixture_one_page "$PROJ" adrs template misshapen)"
  __elsewhere="$(lint__decisions__fixture_one_page "$PROJ" notes 000007-misshapen misshapen)"

  run lint__decisions__form__shape "$ONE_PAGE" "$__template" "$__elsewhere"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__status: passes a record that is approved, and one that names the record that superseded it" {
  __approved="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __superseded="$(lint__decisions__fixture_one_page "$PROJ" adrs 000008-an-earlier-one superseded)"

  run lint__decisions__form__status "$ONE_PAGE" "$__approved" "$__superseded"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__status: flags a record that still says proposed, on its Status line" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments unapproved)"

  run lint__decisions__form__status "$ONE_PAGE" "$__record"
  assert_failure
  assert_output "$__record:3: the status is \"approved\", or \"superseded by\" and a link to the ADR that did"
}

@test "lint__decisions__form__status: passes every file in a repository that names no form" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments unapproved)"

  run lint__decisions__form__status "$(@obj '.config.decisions.folder' adrs)" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__number_width: passes a record whose number has six digits" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__decisions__form__number_width "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__number_width: flags a record padded to four digits, saying the number it should carry" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 0007-fragments one_page)"

  run lint__decisions__form__number_width "$ONE_PAGE" "$__record"
  assert_failure
  assert_output "$__record:1: the record's number is written with 6 digits: 000007"
}

@test "lint__decisions__form__number_width: holds a record to the width lint.json sets" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 0007-fragments one_page)"

  __opts="$(@set "$ONE_PAGE" '.config.decisions.number_digits' 4)"

  run lint__decisions__form__number_width "$__opts" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__citations: passes a linked citation and a bare one inside a fenced example" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__decisions__form__citations "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__citations: flags an unlinked citation and one spelled the old way, each on its line" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-loose loose_citations)"

  run lint__decisions__form__citations "$ONE_PAGE" "$__record"
  assert_failure
  assert_line "$__record:9: link the citation: ADR.3@tool"
  assert_line "$__record:13: cite as ADR.<n>@<repository>: tool ADR 4"
}

@test "lint__decisions__form__page: passes a record within the default page, its fence and figure line free" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"

  run lint__decisions__form__page "$ONE_PAGE" "$__record"
  assert_success
  assert_output ""
}

@test "lint__decisions__form__page: flags a record past the page lint.json sets, saying both counts" {
  __record="$(lint__decisions__fixture_one_page "$PROJ" adrs 000007-fragments one_page)"
  __opts="$(@set "$ONE_PAGE" '.config.decisions.page_words' 20)"

  run lint__decisions__form__page "$__opts" "$__record"
  assert_failure
  assert_output "$__record:1: 41 words of prose; a page is 20"
}

@test "lint__decisions__form__is_named: prints true when lint.json names the one-page form, false otherwise" {
  assert_equal "$(lint__decisions__form__is_named "$ONE_PAGE")" true
  assert_equal "$(lint__decisions__form__is_named "$(@obj '.config.decisions.folder' adrs)")" false
}

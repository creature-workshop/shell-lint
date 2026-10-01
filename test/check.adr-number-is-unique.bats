#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/number-is-unique/api.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo \
    "$BATS_TEST_TMPDIR/repo" \
    000001-a-first.md \
    000002-a-second.md
  )"
}

@test "lint__checks__adrs__number_is_unique__run: passes records whose numbers are their own" {
  run lint__checks__adrs__number_is_unique__run "$(@obj)" \
    "$PROJ/docs/decisions/000001-a-first.md" \
    "$PROJ/docs/decisions/000002-a-second.md"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__number_is_unique__run: flags a record whose number a record beside it carries" {
  __draft="$(lint__checks__adrs__fixture_record "$PROJ" 000002-a-rival.md)"

  run lint__checks__adrs__number_is_unique__run "$(@obj)" "$__draft"
  assert_failure
  assert_output "$__draft:1: number 000002 is taken by 000002-a-second.md"
}

@test "lint__checks__adrs__number_is_unique__run: flags a record whose number the default branch has added since the fork" {
  __draft="$(lint__checks__adrs__fixture_record "$PROJ" 000003-a-third.md)"
  lint__checks__adrs__fixture_upstream_record "$PROJ" 000003-a-landed.md

  run lint__checks__adrs__number_is_unique__run "$(@obj)" "$__draft"
  assert_failure
  assert_output "$__draft:1: number 000003 is taken by 000003-a-landed.md"
}

@test "lint__checks__adrs__number_is_unique__run: passes a record the branch renumbered away from its name on the default branch" {
  git -C "$PROJ" mv docs/decisions/000002-a-second.md docs/decisions/000004-a-second.md
  __rival="$(lint__checks__adrs__fixture_record "$PROJ" 000002-a-rival.md)"

  run lint__checks__adrs__number_is_unique__run "$(@obj)" "$__rival" "$PROJ/docs/decisions/000004-a-second.md"
  assert_success
}

@test "lint__checks__adrs__number_is_unique__run: passes over markdown outside the decisions folder" {
  printf '# notes\n' > "$PROJ/000001-notes.md"

  run lint__checks__adrs__number_is_unique__run "$(@obj)" "$PROJ/000001-notes.md"
  assert_success
  assert_output ""
}

@test "lint__checks__adrs__number_is_unique__run: reads the working tree alone when origin has no default branch" {
  git -C "$PROJ" update-ref -d refs/remotes/origin/main

  run lint__checks__adrs__number_is_unique__run "$(@obj)" "$PROJ/docs/decisions/000001-a-first.md"
  assert_success
}

@test "lint__checks__adrs__number_is_unique__run: flags a one-page record whose directory carries a number another directory holds" {
  __opts="$(@obj '.config.decisions.folder' adrs)"
  lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-fragments one_page >/dev/null
  __rival="$(lint__checks__adrs__fixture_one_page "$PROJ" adrs 000007-singlets one_page)"

  run lint__checks__adrs__number_is_unique__run "$__opts" "$__rival"
  assert_failure
  assert_output "$__rival:1: number 000007 is taken by 000007-fragments"
}

@test "lint__checks__adrs__number_is_unique__run: reads the folder lint.json names, so a record under the default folder is passed over" {
  __opts="$(@obj '.config.decisions.folder' adrs)"
  __draft="$(lint__checks__adrs__fixture_record "$PROJ" 000002-a-rival.md)"

  run lint__checks__adrs__number_is_unique__run "$__opts" "$__draft"
  assert_success
  assert_output ""
}

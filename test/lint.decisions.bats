#!/usr/bin/env bats
# shellcheck disable=SC2034  # globals here configure the sourced code under test

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/form.sh"
  source "$SHELL_LINT_DIR/shell/lint/checks/adrs/fixtures.sh"
  PROJ="$(lint__checks__adrs__fixture_repo "$BATS_TEST_TMPDIR/repo")"
  ONE_PAGE="$(@obj \
    '.config.decisions.folder' adrs \
    '.config.decisions.form' one-page
  )"
}

@test "lint__checks__adrs__form__is_named: prints true when lint.json names the one-page form, false otherwise" {
  assert_equal "$(lint__checks__adrs__form__is_named "$ONE_PAGE")" true
  assert_equal "$(lint__checks__adrs__form__is_named "$(@obj '.config.decisions.folder' adrs)")" false
}

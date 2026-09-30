#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/discovery.sh"
}

# Creates a git repository at <dir> with one commit holding the files named by
# the remaining arguments (each already written under <dir>), and echoes <dir>.
init_repo() {
  __init_repo__dir="$1"
  shift
  git -C "$__init_repo__dir" init -q
  git -C "$__init_repo__dir" config user.email t@example.com
  git -C "$__init_repo__dir" config user.name tester
  git -C "$__init_repo__dir" add "$@"
  git -C "$__init_repo__dir" commit -qm init
  printf '%s' "$__init_repo__dir"
}

@test "lint__language: answers as language__of_path does, by suffix or shebang" {
  __sh="$(fixture bin/tool <<'FIX'
#!/bin/sh -e
true
FIX
)"

  run lint__language lib/x.sh
  assert_output "shell"

  run lint__language "$__sh"
  assert_output "shell"

  run lint__language notes.txt
  assert_output ""
}

@test "lint__is_test_path: a component named as one of the trees, anywhere" {
  run lint__is_test_path test/x.bats test tests
  assert_output "true"

  run lint__is_test_path lib/thing/tests/helper.sh test tests
  assert_output "true"

  run lint__is_test_path testing/helper.sh test tests
  assert_output "false"

  run lint__is_test_path lib/test.sh test tests
  assert_output "false"

  run lint__is_test_path spec/x.sh spec
  assert_output "true"

  run lint__is_test_path test/x.bats spec
  assert_output "false"
}

@test "lint__rel_is_excluded: the directory itself and paths beneath it" {
  run lint__rel_is_excluded test test
  assert_output "true"

  run lint__rel_is_excluded test/lib/helper.sh test planning
  assert_output "true"

  run lint__rel_is_excluded engine/run.sh test planning engine
  assert_output "true"
}

@test "lint__rel_is_excluded: not a sibling sharing a name prefix, and nothing with no prefixes" {
  run lint__rel_is_excluded testing/helper.sh test
  assert_output "false"

  run lint__rel_is_excluded cli/lint
  assert_output "false"
}

@test "lint__rel_is_excluded: a prefix containing a space" {
  run lint__rel_is_excluded "my dir/run.sh" "my dir"
  assert_output "true"

  run lint__rel_is_excluded "my other/run.sh" "my dir"
  assert_output "false"
}

@test "lint__classify: language, scope and path, with scope read off the PROJ-relative path" {
  __proj="$BATS_TEST_TMPDIR/test/proj"
  mkdir -p "$__proj/lib" "$__proj/test"
  printf 'true\n' > "$__proj/lib/x.sh"
  printf 'true\n' > "$__proj/test/x.bats"

  PROJ="$__proj" run lint__classify "$__proj/lib/x.sh" test
  assert_output "$(printf 'shell\tcode\t%s' "$__proj/lib/x.sh")"

  PROJ="$__proj" run lint__classify "$__proj/test/x.bats" test
  assert_output "$(printf 'shell\ttests\t%s' "$__proj/test/x.bats")"

  PROJ="$__proj" run lint__classify "$__proj/test/x.bats" spec
  assert_output "$(printf 'shell\tcode\t%s' "$__proj/test/x.bats")"
}

@test "lint__classify: nothing for a file in a language no check reads" {
  __manifest="$(fixture crate/Cargo.toml <<'FIX'
[package]
name = "crate"
FIX
)"

  run lint__classify "$__manifest" test
  assert_output ""
}

@test "lint__classify: nothing for a file that is not a source" {
  __f="$(fixture notes.txt <<'FIX'
plain prose
FIX
)"

  run lint__classify "$__f"
  assert_output ""
}

@test "lint__discover_tracked: tracked sources as absolute paths, by suffix and shebang" {
  __repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$__repo/cli" "$__repo/lib"
  printf '#!/usr/bin/env bash\ntrue\n' > "$__repo/cli/ok"
  printf 'true\n' > "$__repo/lib/x.sh"
  printf 'BEGIN { }\n' > "$__repo/lib/x.awk"
  printf 'plain\n' > "$__repo/README.txt"
  init_repo "$__repo" cli/ok lib/x.sh lib/x.awk README.txt > /dev/null

  PROJ="$__repo" run lint__discover_tracked '{}'
  assert_success
  assert_line "$(printf 'shell\tcode\t%s/cli/ok' "$__repo")"
  assert_line "$(printf 'shell\tcode\t%s/lib/x.sh' "$__repo")"
  assert_line "$(printf 'awk\tcode\t%s/lib/x.awk' "$__repo")"
  refute_output --partial "README.txt"
}

@test "lint__discover_tracked: skips git-ignored and untracked paths" {
  __repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$__repo/cli" "$__repo/junk"
  printf '#!/usr/bin/env bash\ntrue\n' > "$__repo/cli/ok"
  printf '#!/usr/bin/env bash\ntrue\n' > "$__repo/junk/stale"
  printf 'junk/\n' > "$__repo/.gitignore"
  init_repo "$__repo" cli/ok .gitignore > /dev/null
  printf 'true\n' > "$__repo/cli/untracked.sh"

  PROJ="$__repo" run lint__discover_tracked '{}'
  assert_success
  assert_output --partial "/cli/ok"
  refute_output --partial "junk"
  refute_output --partial "untracked"
}

@test "lint__discover_tracked: leaves out the config's exclude prefixes" {
  __repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$__repo/lib" "$__repo/planning" "$__repo/plans"
  printf 'true\n' > "$__repo/lib/x.sh"
  printf 'true\n' > "$__repo/planning/proto.sh"
  printf 'true\n' > "$__repo/plans/keep.sh"
  init_repo "$__repo" lib/x.sh planning/proto.sh plans/keep.sh > /dev/null

  PROJ="$__repo" run lint__discover_tracked '{"exclude":["planning"]}'
  assert_success
  assert_output --partial "/lib/x.sh"
  assert_output --partial "/plans/keep.sh"
  refute_output --partial "planning/proto.sh"
}

@test "lint__discover_tracked: marks sources under a test tree as tests" {
  __repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$__repo/test"
  printf 'true\n' > "$__repo/test/x.bats"
  init_repo "$__repo" test/x.bats > /dev/null

  PROJ="$__repo" run lint__discover_tracked '{}'
  assert_output "$(printf 'shell\ttests\t%s/test/x.bats' "$__repo")"

  PROJ="$__repo" run lint__discover_tracked '{"tests":["spec"]}'
  assert_output "$(printf 'shell\tcode\t%s/test/x.bats' "$__repo")"
}

@test "lint__discover_tracked: the shellops index includes the cli entrypoints and no vendored test library" {
  PROJ="$SHELLOPS_DIR" run lint__discover_tracked "$(lint__config_load "$SHELLOPS_DIR/lint.json")"
  assert_success
  assert_output --partial "/cli/install"
  refute_output --partial "/test/lib/"
  refute_output --partial "/planning/"
}

@test "lint__select_named: an untracked shell file is kept, as named" {
  __f="$(fixture untracked.sh <<'FIX'
true
FIX
)"

  PROJ="$BATS_TEST_TMPDIR" run lint__select_named '{}' "$__f"
  assert_output "$(printf 'shell\tcode\t%s' "$__f")"
}

@test "lint__select_named: keeps a path containing a space" {
  __f="$(fixture 'has space.sh' <<'FIX'
true
FIX
)"

  PROJ="$BATS_TEST_TMPDIR" run lint__select_named '{}' "$__f"
  assert_output "$(printf 'shell\tcode\t%s' "$__f")"
}

@test "lint__select_named: drops missing paths and non-sources" {
  __md="$(fixture notes.txt <<'FIX'
prose
FIX
)"

  run lint__select_named '{}' "$(printf '%s\n%s' "$BATS_TEST_TMPDIR/absent.sh" "$__md")"
  assert_success
  assert_output ""
}

@test "lint__select_named: excludes apply to a path under PROJ" {
  __proj="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$__proj/planning" "$__proj/lib"
  printf 'true\n' > "$__proj/planning/proto.sh"
  printf 'true\n' > "$__proj/lib/x.sh"

  PROJ="$__proj" run lint__select_named '{"exclude":["planning"]}' \
    "$(printf '%s\n%s' "$__proj/planning/proto.sh" "$__proj/lib/x.sh")"
  assert_output "$(printf 'shell\tcode\t%s/lib/x.sh' "$__proj")"
}

@test "lint__select_named: excludes never reach a path named from outside PROJ" {
  __outside="$BATS_TEST_TMPDIR/elsewhere/planning/proto.sh"
  mkdir -p "$(dirname "$__outside")"
  printf 'true\n' > "$__outside"

  PROJ="$BATS_TEST_TMPDIR/proj" run lint__select_named '{"exclude":["planning"]}' "$__outside"
  assert_output --partial "$__outside"
}

@test "lint__files_for: the paths in the check's languages and scopes" {
  __listing="$(printf 'shell\tcode\t/r/lib/x.sh\nshell\ttests\t/r/test/x.bats\nawk\tcode\t/r/lib/x.awk\njq\tcode\t/r/lib/x.jq')"

  run lint__files_for "$__listing" '["shell"]' '["code"]'
  assert_output "/r/lib/x.sh"

  run lint__files_for "$__listing" '["shell"]' '["code","tests"]'
  assert_line "/r/lib/x.sh"
  assert_line "/r/test/x.bats"

  run lint__files_for "$__listing" '["shell"]' '["tests"]'
  assert_output "/r/test/x.bats"

  run lint__files_for "$__listing" '["awk","jq"]' '["code"]'
  assert_line "/r/lib/x.awk"
  assert_line "/r/lib/x.jq"
  refute_output --partial ".sh"
}

@test "lint__files_for: keeps a path containing a space" {
  __listing="$(printf 'shell\tcode\t/r/has space.sh')"

  run lint__files_for "$__listing" '["shell"]' '["code"]'
  assert_output "/r/has space.sh"
}

@test "lint__is_plain_path: false for a newline or tab, true otherwise" {
  run lint__is_plain_path "$(printf 'a\nb.sh')"
  assert_output false

  run lint__is_plain_path "$(printf 'a\tb.sh')"
  assert_output false

  run lint__is_plain_path "lib/has space.sh"
  assert_output true
}

#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/doc-comment/api.sh"
}

# A throwaway git repo so the staged-mode tests have an index to diff against.
init_repo() {
  __repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$__repo"
  git -C "$__repo" init -q
  git -C "$__repo" config user.email t@example.com
  git -C "$__repo" config user.name tester
}

@test "lint__checks__shell__doc_comment__run: flags a multi-line # doc-block above a function" {
  __fixture="$BATS_TEST_TMPDIR/f.sh"
  cat > "$__fixture" <<'FIX'
# Collects the args into a list.
# POSIX sh cannot write the caller's argv.
parse_args() {
  echo hi
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "f.sh:1:"
  assert_output --partial "use a heredoc doc block"
}

@test "lint__checks__shell__doc_comment__run: flags the @-sigil function form" {
  __fixture="$BATS_TEST_TMPDIR/at.sh"
  cat > "$__fixture" <<'FIX'
# Reads a value.
# Falls back to a default.
@get() {
  echo hi
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_failure
  assert_output --partial "at.sh:1:"
}

@test "lint__checks__shell__doc_comment__run: accepts a heredoc doc block above a function" {
  __fixture="$BATS_TEST_TMPDIR/ok.sh"
  cat > "$__fixture" <<'FIX'
: <<'DOC'
Collects the args into a list.
POSIX sh cannot write the caller's argv.
DOC
parse_args() {
  echo hi
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__doc_comment__run: ignores a single-line # comment above a function" {
  __fixture="$BATS_TEST_TMPDIR/one.sh"
  printf '# a one-line note\nparse_args() {\n  echo hi\n}\n' > "$__fixture"

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__doc_comment__run: ignores a multi-line note not above a function" {
  __fixture="$BATS_TEST_TMPDIR/inline.sh"
  cat > "$__fixture" <<'FIX'
main() {
  # Rebuild the argv from the list (POSIX sh has no
  # arrays); IFS is restored right after.
  set -- a b
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__doc_comment__run: ignores # lines inside a heredoc body" {
  __fixture="$BATS_TEST_TMPDIR/heredoc.sh"
  cat > "$__fixture" <<'FIX'
usage() {
  cat <<EOF
# this is not a comment
# it is heredoc prose
EOF
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__doc_comment__run: an allow marker exempts the block" {
  __fixture="$BATS_TEST_TMPDIR/allow.sh"
  cat > "$__fixture" <<'FIX'
# doc-comment-check: allow -- generated header, kept verbatim
# Collects the args into a list.
# POSIX sh cannot write the caller's argv.
parse_args() {
  echo hi
}
FIX

  run lint__checks__shell__doc_comment__run "$(@obj)" "$__fixture"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__doc_comment__run .added_only: flags a block added in the staged diff" {
  init_repo
  printf 'echo base\n' > "$__repo/f.sh"
  git -C "$__repo" add f.sh
  git -C "$__repo" commit -qm base

  cat >> "$__repo/f.sh" <<'FIX'
# documents foo
# second line
foo() {
  echo hi
}
FIX
  git -C "$__repo" add f.sh

  PROJ="$__repo" run lint__checks__shell__doc_comment__run "$(@obj '.added_only' true)" f.sh
  assert_failure
  assert_output --partial "f.sh:2:"
}

@test "lint__checks__shell__doc_comment__run .added_only: ignores a pre-existing block when the change is elsewhere" {
  init_repo
  cat > "$__repo/f.sh" <<'FIX'
# documents foo
# second line
foo() {
  echo hi
}
FIX
  git -C "$__repo" add f.sh
  git -C "$__repo" commit -qm base

  printf 'echo more\n' >> "$__repo/f.sh"
  git -C "$__repo" add f.sh

  PROJ="$__repo" run lint__checks__shell__doc_comment__run "$(@obj '.added_only' true)" f.sh
  assert_success
  assert_output ""
}

@test "git__staged_added_lines: reports the new-file line numbers added" {
  init_repo
  printf 'a\nb\nc\n' > "$__repo/f.txt"
  git -C "$__repo" add f.txt
  git -C "$__repo" commit -qm base

  printf 'a\nb\nNEW\nc\n' > "$__repo/f.txt"
  git -C "$__repo" add f.txt

  PROJ="$__repo" run git__staged_added_lines f.txt
  assert_success
  assert_output "3"
}


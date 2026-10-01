#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/banner-comment/api.sh"
}

@test "lint__checks__shell__banner_comment__run: flags an equals-sign divider line" {
  __f="$(fixture sectioned.sh <<'FIX'
say() {
  printf 'hi\n'
}

# ==========================================================================
# helpers
# ==========================================================================

helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "sectioned.sh:5:"
  assert_output --partial "sectioned.sh:7:"
  assert_output --partial "banners-mean-split"
}

@test "lint__checks__shell__banner_comment__run: flags a box-drawing banner with an embedded title" {
  __f="$(fixture boxed.sh <<'FIX'
# ── Label items ───────────────────────────────────────────────────────
read_labels() {
  printf 'type/feature\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "boxed.sh:1:"
}

@test "lint__checks__shell__banner_comment__run: flags a hash run beyond the comment leader" {
  __f="$(fixture hashes.sh <<'FIX'
##########
# helpers
##########
helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "hashes.sh:1:"
  assert_output --partial "hashes.sh:3:"
}

@test "lint__checks__shell__banner_comment__run: flags a hyphen banner in an awk source" {
  __f="$(fixture prog.awk <<'FIX'
# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------
{
  print
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "prog.awk:1:"
}

@test "lint__checks__shell__banner_comment__run: flags a banner in a bats source" {
  __f="$(fixture suite.bats <<'FIX'
# ==========================================================================
# the section under test
# ==========================================================================
@test "something" {
  true
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "suite.bats:1:"
}

@test "lint__checks__shell__banner_comment__run: accepts plain comments, short runs, and shebangs" {
  __f="$(fixture clean.sh <<'FIX'
#!/usr/bin/env bash

# A four-run ---- is prose punctuation, not a divider.
# -- and double dashes are ordinary emphasis --
say() {
  printf 'hi\n'  # inline note
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: accepts divider runs inside code, not comments" {
  __f="$(fixture ruler.sh <<'FIX'
rule() {
  printf '==========\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: accepts divider runs inside heredoc bodies" {
  __f="$(fixture usage.sh <<'FIX'
USAGE="$(cat <<EOF
Frames its output like so:
  # ==========
  # the report
  # ==========
EOF
)"

main() {
  printf '%s\n' "$USAGE"
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: an allow marker exempts its own line" {
  __f="$(fixture marked_inline.sh <<'FIX'
# ─────────────── banner-lint: allow -- rendered verbatim in the TUI
frame_top() {
  printf 'frame\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: an allow marker exempts the next three lines" {
  __f="$(fixture marked_above.sh <<'FIX'
# banner-lint: allow -- this frame is load-bearing data
# ==========
# the report
# ==========
frame() {
  printf 'frame\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: an allow marker does not reach a fourth line" {
  __f="$(fixture marked_too_far.sh <<'FIX'
# banner-lint: allow -- covers only the three lines below
# one
# two
# three
# ==========
frame() {
  printf 'frame\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "marked_too_far.sh:5:"
}

@test "lint__checks__shell__banner_comment__run: an allow marker does not reach a floating run four lines down" {
  __f="$(fixture marked_run_too_far.sh <<'FIX'
say() {
  printf 'hi\n'
}

# banner-lint: allow -- reaches only three lines down



# stranded label

helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "marked_run_too_far.sh:9:"
  assert_output --partial "floating comment"
}

@test "lint__checks__shell__banner_comment__run: flags a floating label between functions" {
  __f="$(fixture floating.sh <<'FIX'
say() {
  printf 'hi\n'
}

# helpers

helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "floating.sh:5:"
  assert_output --partial "floating comment"
}

@test "lint__checks__shell__banner_comment__run: flags a floating label between bats cases" {
  # The fixture is assembled with printf: a literal @test line in a heredoc
  # would be rewritten by the bats preprocessor before the shell ever ran.
  __f="$(printf '%s\n' \
    '@test "first" {' \
    '  true' \
    '}' \
    '' \
    '# the section under test' \
    '' \
    '@test "second" {' \
    '  true' \
    '}' \
    | fixture labeled.bats
  )"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "labeled.bats:5:"
}

@test "lint__checks__shell__banner_comment__run: flags a section label between the imports and the first function" {
  __f="$(fixture stealth.sh <<'FIX'
#!/bin/sh

import "lib/api.sh"

# Helpers

helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "stealth.sh:5:"
  assert_output --partial "floating comment"
}

@test "lint__checks__shell__banner_comment__run: flags a floating label in a script defining no functions" {
  __f="$(fixture script.sh <<'FIX'
#!/bin/sh
set -eu

# Section: cleanup phase

rm -f ./scratch
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "script.sh:4:"
  assert_output --partial "floating comment"
}

@test "lint__checks__shell__banner_comment__run: flags a trailing comment run at EOF" {
  __f="$(fixture trailing.sh <<'FIX'
say() {
  printf 'hi\n'
}

# leftover notes nothing below claims
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "trailing.sh:5:"
}

@test "lint__checks__shell__banner_comment__run: accepts a comment attached to the code below" {
  __f="$(fixture attached.sh <<'FIX'
say() {
  printf 'hi\n'
}

# Prints a friendly reply; used by the demo path only.
helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: accepts the file preamble and module doc" {
  __f="$(fixture preamble.sh <<'FIX'
#!/bin/sh

# Module doc: what this file is about, sitting in the preamble
# above the imports and the constants zone.

import "lib/api.sh"

__preamble__LIMIT=3

say() {
  printf 'hi\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: accepts an awk module doc, flags a floating run in the body" {
  __f="$(fixture labeled.awk <<'FIX'
# Module doc for the program: exempt as the preamble.
# Continues over two lines.

function emit(line) {
  print line
}

# emitters

{
  emit($0)
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "labeled.awk:8:"
  refute_output --partial "labeled.awk:1:"
}

@test "lint__checks__shell__banner_comment__run: accepts a jq module doc, flags a floating run in the body" {
  __f="$(fixture labeled.jq <<'FIX'
# Module doc for the filter: exempt as the preamble.

def is_reply: .type == "DiscussionNote";

# helpers

def note_id: .id;
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "labeled.jq:5:"
  refute_output --partial "labeled.jq:1:"
}

@test "lint__checks__shell__banner_comment__run: an allow marker keeps a load-bearing floating run" {
  __f="$(fixture kept.sh <<'FIX'
say() {
  printf 'hi\n'
}

# banner-lint: allow -- this label is load-bearing data
# the-label-a-downstream-parser-greps-for

helper() {
  printf 'help\n'
}
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: a directive-only floating run never flags" {
  # printf for the same reason as the bats-cases fixture above.
  __f="$(printf '%s\n' \
    '@test "first" {' \
    '  true' \
    '}' \
    '' \
    '# shellcheck disable=SC2317' \
    '' \
    '@test "second" {' \
    '  true' \
    '}' \
    | fixture directives.bats
  )"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "cli: flags an extensionless shebang file, wherever it sits" {
  __f="$(fixture cli/publish <<'FIX'
#!/usr/bin/env bash
# ==========================================================================
# Title
# ==========================================================================
main() {
  printf 'published\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check banner-comment "$__f"
  assert_failure
  assert_output --partial "cli/publish:2:"
}

@test "cli: skips an extensionless file with no shell shebang" {
  __f="$(fixture bin/publish <<'FIX'
#!/usr/bin/env python3
# ==========================================================================
def main():
    print("published")
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check banner-comment "$__f"
  assert_success
  assert_output ""
}

@test "cli: flags a divider banner in a jq source" {
  __f="$(fixture flatten.jq <<'FIX'
# ==========================================================================
# reshaping
# ==========================================================================
def flat: [.[]];
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check banner-comment "$__f"
  assert_failure
  assert_output --partial "flatten.jq:1:"
}

@test "cli: skips files that are not shell, awk, jq, or bats sources" {
  __f="$(fixture notes.md <<'FIX'
==========
A markdown thematic break is not a comment banner.
==========
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check banner-comment "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__shell__banner_comment__run: one run over many files names every file's finding" {
  __one="$(fixture one.sh <<'FIX'
a() { :; }

# ==========================================================================
# helpers
# ==========================================================================

b() { :; }
FIX
)"
  __two="$(fixture two.sh <<'FIX'
c() { :; }
# ==========================================================================
# teardown
# ==========================================================================
d() { :; }
FIX
)"

  run lint__checks__shell__banner_comment__run "$(@obj)" "$__one" "$__two"
  assert_failure
  assert_output --partial "one.sh:3:"
  assert_output --partial "two.sh:2:"
}

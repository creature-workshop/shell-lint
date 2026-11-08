#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/awk/style/api.sh"
}

@test "lint__checks__awk__style__run: flags an unbraced if body" {
  __f="$(fixture unbraced-if.awk <<'FIX'
BEGIN {
  if (x) y = 1
}
FIX
)"

  @obj at1
  run lint__checks__awk__style__run "$at1" "$__f"
  assert_failure
  assert_output --partial "unbraced-if.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__checks__awk__style__run: flags an unbraced for body" {
  __f="$(fixture unbraced-for.awk <<'FIX'
BEGIN {
  for (i = 0; i < 3; i++) print i
}
FIX
)"

  @obj at2
  run lint__checks__awk__style__run "$at2" "$__f"
  assert_failure
  assert_output --partial "unbraced for body"
}

@test "lint__checks__awk__style__run: flags an unbraced while body" {
  __f="$(fixture unbraced-while.awk <<'FIX'
BEGIN {
  while (i) i--
}
FIX
)"

  @obj at3
  run lint__checks__awk__style__run "$at3" "$__f"
  assert_failure
  assert_output --partial "unbraced while body"
}

@test "lint__checks__awk__style__run: flags an unbraced else body on the next line" {
  __f="$(fixture unbraced-else.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else
    y = 2
}
FIX
)"

  @obj at4
  run lint__checks__awk__style__run "$at4" "$__f"
  assert_failure
  assert_output --partial "unbraced else body"
}

@test "lint__checks__awk__style__run: flags else-if when the if body is unbraced" {
  __f="$(fixture else-if.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else if (z) y = 2
}
FIX
)"

  @obj at5
  run lint__checks__awk__style__run "$at5" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
  refute_output --partial "unbraced else body"
}

@test "lint__checks__awk__style__run: flags a wide-gap local parameter" {
  __f="$(fixture wide-gap.awk <<'FIX'
function strip_html_comments(s,   at, rest) {
  return s
}
FIX
)"

  @obj at6
  run lint__checks__awk__style__run "$at6" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter 'at'"
  assert_output --partial "local parameter 'rest' must be prefixed with __"
}

@test "lint__checks__awk__style__run: flags an unprefixed parameter after a __ local" {
  __f="$(fixture unprefixed.awk <<'FIX'
function f(line, __item, token) {
  return line
}
FIX
)"

  @obj at7
  run lint__checks__awk__style__run "$at7" "$__f"
  assert_failure
  assert_output --partial "local parameter 'token' must be prefixed with __"
}

@test "lint__checks__awk__style__run: accepts __ locals and braced bodies" {
  __f="$(fixture dunder.awk <<'FIX'
function bullet_reference(line, __item, __token) {
  __item = line
  if (__item != "") {
    split(__item, __token, /[[:space:]]/)
  }
  return __token[1]
}
FIX
)"

  @obj at8
  run lint__checks__awk__style__run "$at8" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts real arguments without a wide gap" {
  __f="$(fixture args.awk <<'FIX'
function note(line, msg) {
  print line msg
}
FIX
)"

  @obj at9
  run lint__checks__awk__style__run "$at9" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts a pattern-action rule" {
  __f="$(fixture pattern.awk <<'FIX'
is_fence($0) { fenced = !fenced; next }
!fenced { print }
FIX
)"

  @obj at10
  run lint__checks__awk__style__run "$at10" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts fence and container globals" {
  __f="$(fixture fence.awk <<'FIX'
function is_code_fence(line, __ch) {
  if (!in_fence) {
    in_fence = 1
    fence_char = __ch
    fence_run = 1
    in_comment = 0
    in_html_code = 0
    html_code_tag = "pre"
  }
  return 1
}
FIX
)"

  @obj at11
  run lint__checks__awk__style__run "$at11" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: does not flag if (x) y inside a string or regex" {
  __f="$(fixture literals.awk <<'FIX'
BEGIN {
  s = "if (x) y"
}
# if (x) y
/if \(x\) y/ { print }
$1 == "if (x) return" { print }
FIX
)"

  @obj at12
  run lint__checks__awk__style__run "$at12" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts a wrapped param list that is not a wide gap" {
  __f="$(fixture wrapped.awk <<'FIX'
function f(
  line,
  __item
) {
  return line
}
FIX
)"

  @obj at13
  run lint__checks__awk__style__run "$at13" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts a clean first-party file" {
  @obj at14
  run lint__checks__awk__style__run "$at14" "$SHELLOPS_DIR/lib/linear/normalize_closing_lists.awk"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: the scanner is clean under its own rules" {
  @obj at15
  run lint__checks__awk__style__run "$at15" "$SHELL_LINT_DIR/shell/lint/awk_style_scan.awk"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: reports every finding in one file" {
  __f="$(fixture multi.awk <<'FIX'
BEGIN {
  if (x) y = 1
  for (i = 0; i < 3; i++) print i
}
FIX
)"

  @obj at16
  run lint__checks__awk__style__run "$at16" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
  assert_output --partial "unbraced for body"
}

@test "lint__checks__awk__style__run: reports findings from every file" {
  __a="$(fixture a.awk <<'FIX'
BEGIN { if (x) y = 1 }
FIX
)"
  __b="$(fixture b.awk <<'FIX'
BEGIN { while (z) z-- }
FIX
)"

  @obj at17
  run lint__checks__awk__style__run "$at17" "$__a" "$__b"
  assert_failure
  assert_output --partial "unbraced if body"
  assert_output --partial "unbraced while body"
}

@test "lint__checks__awk__style__run: flags an unbraced if when the condition has nested parens" {
  __f="$(fixture nested-cond.awk <<'FIX'
BEGIN {
  if (f(x)) y = 1
}
FIX
)"

  @obj at18
  run lint__checks__awk__style__run "$at18" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
}

@test "lint__checks__awk__style__run: flags a same-line unbraced else" {
  __f="$(fixture same-line-else.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else z = 2
}
FIX
)"

  @obj at19
  run lint__checks__awk__style__run "$at19" "$__f"
  assert_failure
  assert_output --partial "unbraced else body"
}

@test "lint__checks__awk__style__run: accepts else-if when both bodies are braced" {
  __f="$(fixture else-if-braced.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else if (z) {
    y = 2
  }
}
FIX
)"

  @obj at20
  run lint__checks__awk__style__run "$at20" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts a braced do-while" {
  __f="$(fixture do-while.awk <<'FIX'
BEGIN {
  do {
    i++
  } while (i < 3)
}
FIX
)"

  @obj at21
  run lint__checks__awk__style__run "$at21" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: unbraced do is a known hole (no unbraced-do finding)" {
  __f="$(fixture unbraced-do.awk <<'FIX'
BEGIN {
  do
    i++
  while (i < 3)
}
FIX
)"

  @obj at22
  run lint__checks__awk__style__run "$at22" "$__f"
  refute_output --partial "unbraced do"
}

@test "lint__checks__awk__style__run: misses if without a paren (conservative)" {
  __f="$(fixture if-no-paren.awk <<'FIX'
BEGIN {
  if x { y = 1 }
}
FIX
)"

  @obj at23
  run lint__checks__awk__style__run "$at23" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: flags a wide-gap after the opening paren" {
  __f="$(fixture wide-gap-paren.awk <<'FIX'
function f(  item) {
  return item
}
FIX
)"

  @obj at24
  run lint__checks__awk__style__run "$at24" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter 'item'"
}

@test "lint__checks__awk__style__run: accepts an empty parameter list" {
  __f="$(fixture no-params.awk <<'FIX'
function f() {
  return 1
}
FIX
)"

  @obj at25
  run lint__checks__awk__style__run "$at25" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: accepts a comment inside a wrapped param list" {
  __f="$(fixture param-comment.awk <<'FIX'
function f(line, # locals
  __item
) {
  return line
}
FIX
)"

  @obj at26
  run lint__checks__awk__style__run "$at26" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: does not treat division as a regex" {
  __f="$(fixture division.awk <<'FIX'
BEGIN {
  n = a / b
  if (n) {
    print n
  }
}
FIX
)"

  @obj at27
  run lint__checks__awk__style__run "$at27" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: skips an escaped quote inside a string" {
  __f="$(fixture escaped-quote.awk <<'FIX'
BEGIN {
  s = "if (x) \" y"
}
FIX
)"

  @obj at28
  run lint__checks__awk__style__run "$at28" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: skips a mid-line comment" {
  __f="$(fixture mid-comment.awk <<'FIX'
BEGIN {
  x = 1 # if (x) y
}
FIX
)"

  @obj at29
  run lint__checks__awk__style__run "$at29" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: skips a regex after a match operator" {
  __f="$(fixture match-regex.awk <<'FIX'
BEGIN {
  if (x ~ /if \(x\) y/) {
    print
  }
}
FIX
)"

  @obj at30
  run lint__checks__awk__style__run "$at30" "$__f"
  assert_success
  assert_output ""
}

@test "cli: reports every finding in every file" {
  __a="$(cli_fixture one.awk <<'FIX'
BEGIN {
  if (x) y = 1
  while (z) z--
}
FIX
)"
  __b="$(cli_fixture two.awk <<'FIX'
function f(line,   item) {
  return line
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check awk-style "$__a" "$__b"
  assert_failure
  assert_output --partial "unbraced if body"
  assert_output --partial "unbraced while body"
  assert_output --partial "wide-gap before parameter 'item'"
}

@test "cli: non-awk named args exit 0 with no scan" {
  __sh="$(cli_fixture drop.sh <<'FIX'
echo hi
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check awk-style "$__sh"
  assert_success
}

@test "cli: skips an awk source under a test tree" {
  __test_dir="$BATS_RUN_TMPDIR/awk-style-lint-cli/$BATS_TEST_NUMBER/test"
  mkdir -p "$__test_dir"
  __skip="$__test_dir/skip.awk"
  cat > "$__skip" <<'FIX'
BEGIN { if (x) y = 1 }
FIX

  run "$SHELL_LINT_DIR/cli/lint" --check awk-style "$__skip"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: flags a wide gap before an already-prefixed local" {
  __f="$(fixture gap-prefixed.awk <<'FIX'
function f(line,   __item) {
  __item = line
  return __item
}
FIX
)"

  @obj at31
  run lint__checks__awk__style__run "$at31" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter '__item'"
}

@test "lint__checks__awk__style__run: flags an if body sitting on the line below" {
  __f="$(fixture next-line-if.awk <<'FIX'
BEGIN {
  if (x)
    y = 1
}
FIX
)"

  @obj at32
  run lint__checks__awk__style__run "$at32" "$__f"
  assert_failure
  assert_output --partial "next-line-if.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__checks__awk__style__run: flags an unbraced body under a condition that wraps" {
  __f="$(fixture wrapped-condition.awk <<'FIX'
BEGIN {
  if (u &&
      v)
    w = 1
}
FIX
)"

  @obj at33
  run lint__checks__awk__style__run "$at33" "$__f"
  assert_failure
  assert_output --partial "wrapped-condition.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__checks__awk__style__run: accepts an identifier that merely opens with a keyword" {
  __f="$(fixture keyword-prefix.awk <<'FIX'
function format_all(line, __iffy) {
  __iffy = line
  while (__iffy != "") {
    __iffy = ""
  }
  return __iffy
}
FIX
)"

  @obj at34
  run lint__checks__awk__style__run "$at34" "$__f"
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: every first-party awk source is clean" {
  run bash -c 'PROJ="$SHELLOPS_DIR" "$SHELL_LINT_DIR/cli/lint" --check awk-style'
  assert_success
  assert_output ""
}

@test "lint__checks__awk__style__run: flags a function below a pattern-action rule, once per file, naming the rule's line" {
  __f="$(fixture lane.awk <<'FIX'
BEGIN {
  x = 1
}

function f() {
  return 1
}

function g() {
  return 2
}
FIX
)"

  @obj at35
  run lint__checks__awk__style__run "$at35" "$__f"
  assert_failure
  assert_output --partial "lane.awk:5:"
  assert_output --partial "function below the rule at line 1"
  refute_output --partial "lane.awk:9:"
}

@test "lint__checks__awk__style__run: passes functions above the rules, and a file of rules or of functions alone" {
  __a="$(fixture ordered.awk <<'FIX'
# A program whose helpers come first.
function f() {
  return 1
}

BEGIN {
  x = f()
}

/x/ {
  print
}
FIX
)"
  __b="$(fixture rules.awk <<'FIX'
BEGIN {
  x = 1
}

END {
  print x
}
FIX
)"
  __c="$(fixture library.awk <<'FIX'
function f() {
  return 1
}
FIX
)"

  @obj at36
  run lint__checks__awk__style__run "$at36" "$__a" "$__b" "$__c"
  assert_success
}

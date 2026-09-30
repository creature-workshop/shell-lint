#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/api.sh"
}

@test "lint__awk_style: flags an unbraced if body" {
  __f="$(fixture unbraced-if.awk <<'FIX'
BEGIN {
  if (x) y = 1
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced-if.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__awk_style: flags an unbraced for body" {
  __f="$(fixture unbraced-for.awk <<'FIX'
BEGIN {
  for (i = 0; i < 3; i++) print i
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced for body"
}

@test "lint__awk_style: flags an unbraced while body" {
  __f="$(fixture unbraced-while.awk <<'FIX'
BEGIN {
  while (i) i--
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced while body"
}

@test "lint__awk_style: flags an unbraced else body on the next line" {
  __f="$(fixture unbraced-else.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else
    y = 2
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced else body"
}

@test "lint__awk_style: flags else-if when the if body is unbraced" {
  __f="$(fixture else-if.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else if (z) y = 2
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
  refute_output --partial "unbraced else body"
}

@test "lint__awk_style: flags a wide-gap local parameter" {
  __f="$(fixture wide-gap.awk <<'FIX'
function strip_html_comments(s,   at, rest) {
  return s
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter 'at'"
  assert_output --partial "local parameter 'rest' must be prefixed with __"
}

@test "lint__awk_style: flags an unprefixed parameter after a __ local" {
  __f="$(fixture unprefixed.awk <<'FIX'
function f(line, __item, token) {
  return line
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "local parameter 'token' must be prefixed with __"
}

@test "lint__awk_style: accepts __ locals and braced bodies" {
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

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts real arguments without a wide gap" {
  __f="$(fixture args.awk <<'FIX'
function note(line, msg) {
  print line msg
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts a pattern-action rule" {
  __f="$(fixture pattern.awk <<'FIX'
is_fence($0) { fenced = !fenced; next }
!fenced { print }
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts fence and container globals" {
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

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: does not flag if (x) y inside a string or regex" {
  __f="$(fixture literals.awk <<'FIX'
BEGIN {
  s = "if (x) y"
}
# if (x) y
/if \(x\) y/ { print }
$1 == "if (x) return" { print }
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts a wrapped param list that is not a wide gap" {
  __f="$(fixture wrapped.awk <<'FIX'
function f(
  line,
  __item
) {
  return line
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts a clean first-party file" {
  run lint__awk_style "$(@obj)" "$SHELLOPS_DIR/lib/linear/normalize_closing_lists.awk"
  assert_success
  assert_output ""
}

@test "lint__awk_style: the scanner is clean under its own rules" {
  run lint__awk_style "$(@obj)" "$SHELL_LINT_DIR/shell/lint/awk_style_scan.awk"
  assert_success
  assert_output ""
}

@test "lint__awk_style: reports every finding in one file" {
  __f="$(fixture multi.awk <<'FIX'
BEGIN {
  if (x) y = 1
  for (i = 0; i < 3; i++) print i
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
  assert_output --partial "unbraced for body"
}

@test "lint__awk_style: reports findings from every file" {
  __a="$(fixture a.awk <<'FIX'
BEGIN { if (x) y = 1 }
FIX
)"
  __b="$(fixture b.awk <<'FIX'
BEGIN { while (z) z-- }
FIX
)"

  run lint__awk_style "$(@obj)" "$__a" "$__b"
  assert_failure
  assert_output --partial "unbraced if body"
  assert_output --partial "unbraced while body"
}

@test "lint__awk_style: flags an unbraced if when the condition has nested parens" {
  __f="$(fixture nested-cond.awk <<'FIX'
BEGIN {
  if (f(x)) y = 1
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced if body"
}

@test "lint__awk_style: flags a same-line unbraced else" {
  __f="$(fixture same-line-else.awk <<'FIX'
BEGIN {
  if (x) {
    y = 1
  } else z = 2
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "unbraced else body"
}

@test "lint__awk_style: accepts else-if when both bodies are braced" {
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

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts a braced do-while" {
  __f="$(fixture do-while.awk <<'FIX'
BEGIN {
  do {
    i++
  } while (i < 3)
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: unbraced do is a known hole (no unbraced-do finding)" {
  __f="$(fixture unbraced-do.awk <<'FIX'
BEGIN {
  do
    i++
  while (i < 3)
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  refute_output --partial "unbraced do"
}

@test "lint__awk_style: misses if without a paren (conservative)" {
  __f="$(fixture if-no-paren.awk <<'FIX'
BEGIN {
  if x { y = 1 }
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: flags a wide-gap after the opening paren" {
  __f="$(fixture wide-gap-paren.awk <<'FIX'
function f(  item) {
  return item
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter 'item'"
}

@test "lint__awk_style: accepts an empty parameter list" {
  __f="$(fixture no-params.awk <<'FIX'
function f() {
  return 1
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: accepts a comment inside a wrapped param list" {
  __f="$(fixture param-comment.awk <<'FIX'
function f(line, # locals
  __item
) {
  return line
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: does not treat division as a regex" {
  __f="$(fixture division.awk <<'FIX'
BEGIN {
  n = a / b
  if (n) {
    print n
  }
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: skips an escaped quote inside a string" {
  __f="$(fixture escaped-quote.awk <<'FIX'
BEGIN {
  s = "if (x) \" y"
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: skips a mid-line comment" {
  __f="$(fixture mid-comment.awk <<'FIX'
BEGIN {
  x = 1 # if (x) y
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: skips a regex after a match operator" {
  __f="$(fixture match-regex.awk <<'FIX'
BEGIN {
  if (x ~ /if \(x\) y/) {
    print
  }
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
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

@test "lint__awk_style: flags a wide gap before an already-prefixed local" {
  __f="$(fixture gap-prefixed.awk <<'FIX'
function f(line,   __item) {
  __item = line
  return __item
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "wide-gap before parameter '__item'"
}

@test "lint__awk_style: flags an if body sitting on the line below" {
  __f="$(fixture next-line-if.awk <<'FIX'
BEGIN {
  if (x)
    y = 1
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "next-line-if.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__awk_style: flags an unbraced body under a condition that wraps" {
  __f="$(fixture wrapped-condition.awk <<'FIX'
BEGIN {
  if (u &&
      v)
    w = 1
}
FIX
)"

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "wrapped-condition.awk:2:"
  assert_output --partial "unbraced if body"
}

@test "lint__awk_style: accepts an identifier that merely opens with a keyword" {
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

  run lint__awk_style "$(@obj)" "$__f"
  assert_success
  assert_output ""
}

@test "lint__awk_style: every first-party awk source is clean" {
  run bash -c 'PROJ="$SHELLOPS_DIR" "$SHELL_LINT_DIR/cli/lint" --check awk-style'
  assert_success
  assert_output ""
}

@test "lint__awk_style: flags a function below a pattern-action rule, once per file, naming the rule's line" {
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

  run lint__awk_style "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "lane.awk:5:"
  assert_output --partial "function below the rule at line 1"
  refute_output --partial "lane.awk:9:"
}

@test "lint__awk_style: passes functions above the rules, and a file of rules or of functions alone" {
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

  run lint__awk_style "$(@obj)" "$__a" "$__b" "$__c"
  assert_success
}

#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  source "$SHELL_LINT_DIR/shell/lint/checks.sh"
}

@test "lint__registry__names: every check folder here in sorted path order, then shellops' own checks" {
  run lint__registry__names
  assert_success
  __own="$(find "$SHELL_LINT_DIR/shell/lint/checks" -name '*.check.op.sh' | wc -l)"
  __shellops="$(find "$SHELLOPS_DIR/lib" -name '*.check.op.sh' | grep -vc '/lib/lint/')"
  assert_equal "$(@len "$output")" "$((__own + __shellops))"
  assert_equal "$(@get "$output" '.[0]')" adr-citations
  assert_equal "$(@get "$output" '.[1]')" adr-number-is-unique
  assert_equal "$(@get "$output" '.[2]')" adr-number-width
  assert_equal "$(@get "$output" '.[-1]')" string-tests
}

@test "lint__load_checks: a plugin under a root with a space in its path loads and registers" {
  __root="$BATS_TEST_TMPDIR/has space/lib"
  mkdir -p "$__root"
  cp "$TEST_DIR/fixtures/lint/demo-check.check.op.sh" "$__root/"

  lint__load_checks "$BATS_TEST_TMPDIR/has space"
  run lint__check_registered demo-check
  assert_output true
}

@test "every registered check answers each contract role" {
  __missing=""
  for __name in $(@join "$(lint__registry__names)" ' '); do
    for __role in run languages scopes summary hint; do
      command -v "$(lint__check_fn "$__name" "$__role")" > /dev/null 2>&1 \
        || __missing="$__missing $__name:$__role"
    done
  done
  assert_equal "$__missing" ""
}

@test "lint__check_prefix / lint__check_fn: dashes become underscores" {
  run lint__check_prefix doc-comment
  assert_output doc_comment

  run lint__check_fn duplicate-file-doc run
  assert_output duplicate_file_doc_run
}

@test "lint__check_registered: true for a check, false for a stranger" {
  run lint__check_registered indent
  assert_output true

  run lint__check_registered bogus
  assert_output false
}

@test "lint__unknown_checks: the names no check answers to" {
  run lint__unknown_checks "$(@arr indent bogus awk-style nope)"
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[0]')" "bogus"
  assert_equal "$(@get "$output" '.[1]')" "nope"

  run lint__unknown_checks "$(@arr indent)"
  assert_equal "$(@len "$output")" 0
}

@test "role readers: languages, scopes, summary and hint come from the check's roles" {
  run lint__check_languages banner-comment
  assert_equal "$(@len "$output")" 3
  assert_equal "$(@get "$output" '.[1]')" awk

  run lint__check_scopes banner-comment
  assert_equal "$(@len "$output")" 2
  assert_equal "$(@get "$output" '.[1]')" tests

  run lint__check_scopes raw-jq
  assert_output '["code"]'

  run lint__check_summary indent
  assert_output --partial "multiple of the configured width"

  run lint__check_hint indent
  assert_output --partial "Reindent the flagged lines"
}

@test "lint__check_verdict: the summary as the error headline, then the hint as HINT lines" {
  run lint__check_verdict raw-jq
  assert_line --index 0 --regexp '^ERROR: No raw jq or opx'
  assert_line --index 1 --regexp '^HINT: Use the @-sigil verbs'
  assert_equal "${#lines[@]}" 4
}

@test "lint__explain_check: the summary, then the hint" {
  run lint__explain_check raw-jq
  assert_line --index 0 --regexp '^No raw jq or opx'
  assert_line --index 1 --regexp '^Use the @-sigil verbs'
  assert_equal "${#lines[@]}" 4
}

@test "lint__check_run: hands opts and files to the check's run role" {
  __f="$BATS_TEST_TMPDIR/tabbed.sh"
  printf '#!/bin/sh\n\tx=1\n' > "$__f"

  run lint__check_run indent "$(@obj)" "$__f"
  assert_failure
  assert_output --partial "tabbed.sh:2:"
}

@test "lint__describe_checks: one line per check with its languages, scopes and rule" {
  run lint__describe_checks
  assert_success
  assert_equal "${#lines[@]}" "$(@len "$(lint__registry__names)")"
  assert_line --regexp '^indent +shell +code, tests +Leading whitespace'
  assert_line --regexp '^raw-jq +shell +code +No raw jq'
}

@test "lint__register_check: refuses a check missing a role, naming it" {
  demo_languages() { @arr shell; }
  demo_summary() { printf 'A demo.\n'; }

  run lint__register_check demo
  assert_failure
  assert_output --partial "missing contract function(s): demo_run, demo_scopes"

  run lint__check_registered demo
  assert_output false
}

@test "lint__register_check: refuses a language or scope word it does not know, naming each" {
  odd_run() { :; }
  odd_summary() { printf 'Odd.\n'; }
  odd_hint() { printf 'Be even.\n'; }
  odd_languages() { @arr shell perl; }
  odd_scopes() { @arr code prod; }

  run lint__register_check odd
  assert_failure
  assert_output --partial "uses unknown language(s): perl; scope(s): prod"

  run lint__check_registered odd
  assert_output false
}

@test "lint__load_check: loads a plugin's contract, registers it once, and is quiet on a repeat" {
  @check.demo-load() {
    @summary() { printf 'A demo.\n'; }
    @hint() { printf 'Demo it.\n'; }
    @languages() { @arr awk; }
    @scopes() { @arr code; }
    @run() { :; }
  }
  __before="$(@len "$(lint__registry__names)")"

  lint__load_check demo-load
  lint__load_check demo-load

  run lint__check_registered demo-load
  assert_output true
  assert_equal "$(@len "$(lint__registry__names)")" "$((__before + 1))"
  run demo_load_languages
  assert_output '["awk"]'
}

@test "lint__check_name_of: the filename without its directory and suffix" {
  run lint__check_name_of shell/lint/checks/shell/duplicate-file-doc/duplicate-file-doc.check.op.sh
  assert_output duplicate-file-doc
}

@test "interpreter__load_check: re-homes the roles under the check's prefix and refuses a gap" {
  @check.demo-check() {
    @summary() { printf 'A demo.\n'; }
    @hint() { printf 'Demo it.\n'; }
    @languages() { @arr jq; }
    @scopes() { @arr code; }
    @run() { printf 'ran %s\n' "$#"; }
  }
  interpreter__load_check demo-check @check.demo-check

  run demo_check_run "$(@obj)" a b
  assert_output "ran 3"
  run demo_check_languages
  assert_output '["jq"]'

  @check.gappy() {
    @run() { :; }
  }
  run interpreter__load_check gappy @check.gappy
  assert_failure
  assert_output --partial "check gappy missing required role(s): languages scopes summary hint"
}

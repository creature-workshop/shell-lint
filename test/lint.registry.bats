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
  @len at1 "$output"
  assert_equal "$at1" "$((__own + __shellops))"
  @get at2 "$output" '.[0]'
  assert_equal "$at2" adr-citations
  @get at3 "$output" '.[1]'
  assert_equal "$at3" adr-number-is-unique
  @get at4 "$output" '.[2]'
  assert_equal "$at4" adr-number-width
  @get at5 "$output" '.[-1]'
  assert_equal "$at5" string-tests
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
  @join at6 "$(lint__registry__names)" ' '
  for __name in $at6; do
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
  @arr at7 indent bogus awk-style nope
  run lint__unknown_checks "$at7"
  @len at8 "$output"
  assert_equal "$at8" 2
  @get at9 "$output" '.[0]'
  assert_equal "$at9" "bogus"
  @get at10 "$output" '.[1]'
  assert_equal "$at10" "nope"

  @arr at11 indent
  run lint__unknown_checks "$at11"
  @len at12 "$output"
  assert_equal "$at12" 0
}

@test "role readers: languages, scopes, summary and hint come from the check's roles" {
  run lint__check_languages banner-comment
  @len at13 "$output"
  assert_equal "$at13" 3
  @get at14 "$output" '.[1]'
  assert_equal "$at14" awk

  run lint__check_scopes banner-comment
  @len at15 "$output"
  assert_equal "$at15" 2
  @get at16 "$output" '.[1]'
  assert_equal "$at16" tests

  run lint__check_scopes raw-jq
  assert_output '["code"]'

  run lint__check_summary indent
  assert_output --partial "multiple of the configured width"

  run lint__check_hint indent
  assert_output --partial "Reindent the flagged lines"
}

@test "lint__check_language_words, lint__check_scope_words: the words registration kept, space-separated, and nothing for a stranger" {
  @join at17 "$(lint__check_languages banner-comment)" ' '
  assert_equal "$(lint__check_language_words banner-comment)" "$at17"
  assert_equal "$(lint__check_scope_words indent)" "code tests"
  assert_equal "$(lint__check_scope_words raw-jq)" "code"
  assert_equal "$(lint__check_language_words bogus)" ""
}

@test "lint__register_check: reads @languages and @scopes once, at registration" {
  counted_run() { :; }
  counted_summary() { printf 'Counted.\n'; }
  counted_hint() { printf 'Count it.\n'; }
  counted_languages() { printf '%s\n' "$BATS_TEST_TMPDIR/counted" >> "$BATS_TEST_TMPDIR/reads"; @arr __counted_languages__out shell awk; println "$__counted_languages__out"; }
  counted_scopes() { @arr __counted_scopes__out tests; println "$__counted_scopes__out"; }

  lint__register_check counted
  lint__check_language_words counted >/dev/null
  lint__check_scope_words counted >/dev/null
  lint__describe_checks >/dev/null

  assert_equal "$(wc -l < "$BATS_TEST_TMPDIR/reads")" 1
  assert_equal "$(lint__check_language_words counted)" "shell awk"
  assert_equal "$(lint__check_scope_words counted)" "tests"
  run lint__describe_checks
  assert_line --regexp '^counted +shell, awk +tests +Counted\.'
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

  @obj at18
  run lint__check_run indent "$at18" "$__f"
  assert_failure
  assert_output --partial "tabbed.sh:2:"
}

@test "lint__describe_checks: one line per check with its languages, scopes and rule" {
  run lint__describe_checks
  assert_success
  @len at19 "$(lint__registry__names)"
  assert_equal "${#lines[@]}" "$at19"
  assert_line --regexp '^indent +shell +code, tests +Leading whitespace'
  assert_line --regexp '^raw-jq +shell +code +No raw jq'
}

@test "lint__register_check: refuses a check missing a role, naming it" {
  demo_languages() { @arr __demo_languages__out shell; println "$__demo_languages__out"; }
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
  odd_languages() { @arr __odd_languages__out shell perl; println "$__odd_languages__out"; }
  odd_scopes() { @arr __odd_scopes__out code prod; println "$__odd_scopes__out"; }

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
    @languages() { @arr __languages__out awk; println "$__languages__out"; }
    @scopes() { @arr __scopes__out code; println "$__scopes__out"; }
    @run() { :; }
  }
  @len __before "$(lint__registry__names)"

  lint__load_check demo-load
  lint__load_check demo-load

  run lint__check_registered demo-load
  assert_output true
  @len at20 "$(lint__registry__names)"
  assert_equal "$at20" "$((__before + 1))"
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
    @languages() { @arr __languages__out jq; println "$__languages__out"; }
    @scopes() { @arr __scopes__out code; println "$__scopes__out"; }
    @run() { printf 'ran %s\n' "$#"; }
  }
  interpreter__load_check demo-check @check.demo-check

  @obj at21
  run demo_check_run "$at21" a b
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

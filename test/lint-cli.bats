#!/usr/bin/env bats

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/run.sh"

  # A fresh project directory per case, outside any test tree: BATS_TEST_TMPDIR
  # sits at <run tmpdir>/test/<n>, and most checks skip test paths.
  PROJ_DIR="$BATS_RUN_TMPDIR/lint-cli/$BATS_TEST_NUMBER"
}

# Writes <content> to <name> under PROJ_DIR and echoes the path.
project_file() {
  __project_file__path="$PROJ_DIR/${1}"
  mkdir -p "$(dirname "$__project_file__path")"
  cat > "$__project_file__path"
  printf '%s' "$__project_file__path"
}

# Runs cli/lint from the fixture project, as a hook would, with PROJ pointed
# at it.
lint() {
  cd "$PROJ_DIR" && PROJ="$PROJ_DIR" "$SHELL_LINT_DIR/cli/lint" "$@"
}

@test "lint__run: runs every check over the files it reads and reports each" {
  __f="$(project_file lib/messy.sh <<'FIX'
: <<'DOC'
Reports whether the version parses, formerly "is_semver".

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
   printf 'true\n'
}
FIX
)"
  __listing="$(PROJ="$PROJ_DIR" lint__select_named '{}' "$__f")"

  run lint__run "$(@obj '.added_only' false '.config' '{}')" "$(@arr)" "$__listing"
  assert_failure
  assert_output --partial "Comment prose describes what the code does now"
  assert_output --partial "A doc block carries no TODO"
  assert_output --partial "indentation is not a multiple of 2"
}

@test "lint__run: a selection narrows the run to the checks named" {
  __f="$(project_file lib/messy.sh <<'FIX'
: <<'DOC'
Reports whether the version parses, formerly "is_semver".

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"
  __listing="$(PROJ="$PROJ_DIR" lint__select_named '{}' "$__f")"

  run lint__run "$(@obj '.added_only' false '.config' '{}')" "$(@arr backward-reference)" "$__listing"
  assert_failure
  assert_output --partial "Comment prose describes what the code does now"
  refute_output --partial "A doc block carries no TODO"
}

@test "lint__run: a check held to new lines is skipped in a full run and named once" {
  __f="$(project_file lib/raw.sh <<'FIX'
raw__read_name() {
  printf '%s' "$1" | jq -r '.name'
}
FIX
)"
  __listing="$(PROJ="$PROJ_DIR" lint__select_named '{}' "$__f")"

  run lint__run "$(@obj '.added_only' false '.config' '{"added_only":["raw-jq"]}')" "$(@arr)" "$__listing"
  assert_success
  assert_output --partial "held to new lines only, per the lint declaration's added_only: raw-jq"
  refute_output --partial "Raw jq/opx"
}

@test "lint__run: a check the declaration turns off is skipped in every run and named once" {
  __f="$(project_file lib/raw.sh <<'FIX'
raw__read_name() {
  printf '%s' "$1" | jq -r '.name'
}
FIX
)"
  __listing="$(PROJ="$PROJ_DIR" lint__select_named '{}' "$__f")"

  run lint__run "$(@obj '.added_only' false '.config' '{"disabled":["raw-jq"]}')" "$(@arr)" "$__listing"
  assert_success
  assert_output --partial "turned off, per the lint declaration's disabled: raw-jq"
  refute_output --partial "Raw jq/opx"

  run lint__run "$(@obj '.added_only' true '.config' '{"disabled":["raw-jq"]}')" "$(@arr)" "$__listing"
  assert_success
  assert_output --partial "turned off, per the lint declaration's disabled: raw-jq"
  refute_output --partial "Raw jq/opx"
}

@test "lint__run: returns 0 with nothing to say for a clean file" {
  __f="$(project_file shell/clean.sh <<'FIX'
#!/bin/sh

: <<'PUB_FUN'
Prints a greeting.
PUB_FUN
clean__greet() {
  printf 'hi\n'
}
FIX
)"
  __listing="$(PROJ="$PROJ_DIR" lint__select_named '{}' "$__f")"

  run lint__run "$(@obj '.added_only' false '.config' '{}')" "$(@arr)" "$__listing"
  assert_success
  assert_output ""
}

@test "cli: --list prints every registered check with its languages, scopes and rule" {
  run "$SHELL_LINT_DIR/cli/lint" --list
  assert_success
  assert_line --regexp '^indent +shell +code, tests +Leading whitespace'
  assert_line --regexp '^banner-comment +shell, awk, jq +code, tests '
  assert_line --regexp '^awk-style +awk +code +awk control-flow'
}

@test "cli: --explain prints a check's rule and how to satisfy it, and refuses a stranger" {
  run "$SHELL_LINT_DIR/cli/lint" --explain empty-literals
  assert_success
  assert_line --index 0 --regexp '^Empty arrays and objects are built with @arr and @obj'
  assert_line --index 1 --regexp '^Build them with the constructors'

  run "$SHELL_LINT_DIR/cli/lint" --explain bogus
  assert_failure
  assert_output --partial "Unknown --check name: bogus"

  run "$SHELL_LINT_DIR/cli/lint" --explain
  assert_failure
}

@test "cli: a failing check's findings come first, then its rule as the error and its hint" {
  __f="$(project_file lib/raw.sh <<'FIX'
raw__read_name() {
  printf '%s' "$1" | jq -r '.name'
}
FIX
)"

  run lint --check raw-jq "$__f"
  assert_failure
  assert_line --index 0 --regexp 'lib/raw.sh:2:'
  assert_line --index 1 --regexp '^ERROR: No raw jq or opx outside the structs API'
  assert_line --index 2 --regexp '^HINT: Use the @-sigil verbs'
}

@test "cli: --help prints the usage" {
  run "$SHELL_LINT_DIR/cli/lint" --help
  assert_success
  assert_output --partial "Usage: lint"
}

@test "cli: rejects an unknown option and a --check with no value" {
  run "$SHELL_LINT_DIR/cli/lint" --bogus
  assert_failure
  assert_output --partial "Unknown option: --bogus"

  run "$SHELL_LINT_DIR/cli/lint" --check
  assert_failure
  assert_output --partial "Missing value for --check"
}

@test "cli: --check rejects unknown names, listing the known ones" {
  run "$SHELL_LINT_DIR/cli/lint" --check bogus --check indent --check nope
  assert_failure
  assert_output --partial "Unknown --check name: bogus, nope"
  assert_output --partial "Expected one of: adr-citations adr-number-is-unique adr-number-width"
}

@test "cli: --check narrows to the checks named, repeatable" {
  __f="$(project_file lib/messy.sh <<'FIX'
: <<'DOC'
Reports whether the version parses, formerly "is_semver".

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run lint --check doc-block-tracker "$__f"
  assert_failure
  assert_output --partial "A doc block carries no TODO"
  refute_output --partial "Comment prose describes what the code does now"

  run lint --check doc-block-tracker --check backward-reference "$__f"
  assert_failure
  assert_output --partial "A doc block carries no TODO"
  assert_output --partial "Comment prose describes what the code does now"
}

@test "cli: reads \$PROJ/lint.json and holds its added_only checks to new lines" {
  __f="$(project_file lib/raw.sh <<'FIX'
raw__read_name() {
  printf '%s' "$1" | jq -r '.name'
}
FIX
)"
  echo '{"added_only":["raw-jq"]}' > "$PROJ_DIR/lint.json"

  run lint "$__f"
  assert_success
  assert_output --partial "held to new lines only, per the lint declaration's added_only: raw-jq"

  run lint --check raw-jq "$__f"
  assert_success
  assert_output --partial "held to new lines only"
}

@test "cli: a malformed lint.json ends the run" {
  __f="$(project_file lib/clean.sh <<'FIX'
true
FIX
)"
  echo '{"indent":{"width":"two"}}' > "$PROJ_DIR/lint.json"

  run lint "$__f"
  assert_failure
  refute_output --partial "clean.sh"
}

@test "cli: --added-only reports only the lines the staged diff added and runs the held checks" {
  stage_over_baseline "$PROJ_DIR" lib/mod.sh 'build() {
  acc="{}"
}' 'build() {
  acc="{}"
  jq -r .name data.json
}'
  echo '{"added_only":["raw-jq"]}' > "$PROJ_DIR/lint.json"

  run lint --added-only lib/mod.sh
  assert_failure
  assert_output --partial 'lib/mod.sh:3:'
  assert_output --partial "ERROR: No raw jq or opx outside the structs API"
  refute_output --partial 'lib/mod.sh:2:'
  refute_output --partial "held to new lines only"
}

@test "cli: --added-only accepts an absolute path to the staged file" {
  stage_over_baseline "$PROJ_DIR" lib/mod.sh 'build() {
  printf x
}' 'build() {
  printf x
  extra="{}"
}'

  run lint --added-only --check empty-literals "$PROJ_DIR/lib/mod.sh"
  assert_failure
  assert_output --partial 'lib/mod.sh:3:'
}

@test "cli: --added-only holds a check with no staged scanner of its own to the added lines" {
  __base="$(cat <<'FIX'
say() {
  printf hi
}

# ==========
# helpers
# ==========

helper() {
  printf help
}
FIX
)"
  __staged="$(cat <<'FIX'
say() {
  printf hi
}

# ==========
# helpers
# ==========

helper() {
  printf help
}

other() {
  printf other
}
FIX
)"
  stage_over_baseline "$PROJ_DIR" lib/mod.sh "$__base" "$__staged"

  run lint --added-only --check banner-comment lib/mod.sh
  assert_success
  assert_output ""
}

@test "cli: --added-only reports such a check's new finding on its line alone, with the verdict" {
  __base="$(cat <<'FIX'
say() {
  printf hi
}

# ==========
# helpers
# ==========

helper() {
  printf help
}
FIX
)"
  __staged="$(cat <<'FIX'
say() {
  printf hi
}

# ==========
# helpers
# ==========

helper() {
  printf help
}

# ----------
# more
# ----------

other() {
  printf other
}
FIX
)"
  stage_over_baseline "$PROJ_DIR" lib/mod.sh "$__base" "$__staged"

  run lint --added-only --check banner-comment "$PROJ_DIR/lib/mod.sh"
  assert_failure
  assert_output --partial 'lib/mod.sh:13:'
  assert_output --partial 'lib/mod.sh:15:'
  refute_output --partial 'lib/mod.sh:5:'
  refute_output --partial 'lib/mod.sh:7:'
  assert_output --partial "ERROR: No divider or free-floating banner comments"
}

@test "cli: skips a named file that is not a shell, awk, or jq source" {
  __f="$(project_file notes.md <<'FIX'
# ==========================================================================
FIX
)"

  run lint "$__f"
  assert_success
  assert_output ""
}

@test "cli: a check that polices test trees sees a bats file; one that does not, skips it" {
  __f="$(project_file test/thing.bats <<'FIX'
# ==========================================================================
# cases
# ==========================================================================
: <<'DOC'
Formerly a helper.
DOC
@test "x" {
  true
}
FIX
)"

  run lint "$__f"
  assert_failure
  assert_output --partial "No divider or free-floating banner comments"
  refute_output --partial "Comment prose describes what the code does now"
}

@test "cli: an excluded directory is skipped for a named path under PROJ" {
  __f="$(project_file planning/proto.sh <<'FIX'
build() {
   printf x
}
FIX
)"
  echo '{"exclude":["planning"]}' > "$PROJ_DIR/lint.json"

  run lint "$__f"
  assert_success
  assert_output ""
}

@test "cli: refuses a path containing a newline rather than skipping it" {
  __f="$(printf '%s/bad\nname.sh' "$BATS_TEST_TMPDIR")"
  printf 'true\n' > "$__f"

  run "$SHELL_LINT_DIR/cli/lint" "$__f"
  assert_failure
  assert_output --partial "Cannot lint a path containing a newline or tab"
}

@test "cli: with no files, sweeps the tracked sources under PROJ" {
  __odd="$(printf 'build() {\n   printf x\n}')"
  stage_over_baseline "$PROJ_DIR" lib/mod.sh "$__odd" "$__odd
# tracked, not staged"
  git -C "$PROJ_DIR" commit -qm staged

  run lint --check indent
  assert_failure
  assert_output --partial "lib/mod.sh:2:"
}

@test "cli: --check narrows to the one check named" {
  __f="$(cli_fixture lib/tracked.sh <<'FIX'
: <<'DOC'
Reports whether the version parses.

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check backward-reference "$__f"
  assert_success

  run "$SHELL_LINT_DIR/cli/lint" --check doc-block-tracker "$__f"
  assert_failure
}

@test "cli: with no --check, every check runs and each is reported" {
  __f="$(cli_fixture lib/messy.sh <<'FIX'
: <<'DOC'
Reports whether the version parses, formerly "is_semver".

TODO(OPS-237): the builtin duplicates this.
DOC
is_valid() {
  printf 'true\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_failure
  assert_output --partial "Comment prose describes what the code does now"
  assert_output --partial "A doc block carries no TODO"
}

@test "cli: skips files that are not shell sources" {
  __f="$(cli_fixture notes.md <<'FIX'
A doc block opens with `: <<'DOC'`.
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

@test "cli: skips test sources, which document themselves as cases" {
  __f="$(cli_fixture test/some_helper.sh <<'FIX'
: <<'DOC'
Builds a fixture, formerly "make_file".
DOC
build() {
  printf 'built\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

@test "cli: skips a planning tree the same way it skips a test tree" {
  __f="$(cli_fixture planning/proto.sh <<'FIX'
: <<'DOC'
Applies the labels a review earned.
DOC
build() {
  printf 'built\n'
}
FIX
)"

  run "$SHELL_LINT_DIR/cli/lint" --check duplicate-file-doc --check oversized-doc-block --check backward-reference --check doc-block-tracker "$__f"
  assert_success
  assert_output ""
}

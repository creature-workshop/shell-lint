#!/bin/sh

: <<'FRAGMENT'
The repository's lint settings: $PROJ/lint.json.

The file is read once per run, checked against lint.schema.json, and handed to
every check inside its options as `.config`. It is optional, and so is every
key in it: each reader here has a default, so a repository with no file gets
the house settings. To add a setting, add it to the schema and add a reader
here; the schema is what tells a repository its file is wrong.
FRAGMENT

__lint__config__SCHEMA="$SHELL_LINT_DIR/shell/lint/lint.schema.json"

: <<'PUB_FUN'
Prints the repository's lint settings as a struct, checked against
lint.schema.json. No file gives an empty object. A file that is not JSON, or
that breaks the schema, fails the call and says why.

Usage: lint__config_load            # $PROJ/lint.json
       lint__config_load <path>     # a named file
PUB_FUN
lint__config_load() {
  __lint__config_load__file="${1:-$PROJ/lint.json}"
  if [ ! -f "$__lint__config_load__file" ]; then
    @obj
    return 0
  fi

  @load "$__lint__config_load__file" "$__lint__config__SCHEMA"
}

: <<'PUB_FUN'
Prints the directories a repository keeps its own lint checks under, as a
struct array of PROJ-relative paths; empty by default.
PUB_FUN
lint__config_check_roots() {
  @get "$1" '.checks' "$(@arr)"
}

: <<'PUB_FUN'
Prints the number of spaces one indent level is, 2 by default.
PUB_FUN
lint__config_indent_width() {
  @get "$1" '.indent.width' 2
}

: <<'PUB_FUN'
Prints true when leading tabs are allowed, false by default.
PUB_FUN
lint__config_allow_tabs() {
  @get "$1" '.indent.tabs' false
}

: <<'PUB_FUN'
Prints the directory names that mark a test tree, as a struct array; test and
tests by default. A file under a directory with one of these names, anywhere
in its path, is in the tests scope.
PUB_FUN
lint__config_test_trees() {
  @get "$1" '.tests' "$(@arr test tests)"
}

: <<'PUB_FUN'
Prints the directories, relative to the repository root, that no check looks
in; a struct array, empty by default.
PUB_FUN
lint__config_excludes() {
  @get "$1" '.exclude' "$(@arr)"
}

: <<'PUB_FUN'
Prints the roots a library file sits under, relative to the repository root,
as a struct array: the list lint.json's library_roots names; otherwise
scripts, shell and src, the homes a consumer keeps its shell in, or lib and
interpreter when the repository is shellops itself, PROJ standing in
SHELLOPS_DIR (ADR 000045). A file under one is a module, its namespace the
path under the root; a consumer's root lib/ is its product's until named.
PUB_FUN
lint__config_library_roots() {
  @get "$1" '.library_roots' "$(__lint__config__default_library_roots)"
}

: <<'FUN'
Prints the library roots a repository has when lint.json names none, as a
struct array: shellops' own when PROJ stands in SHELLOPS_DIR, a consumer's
otherwise.
FUN
__lint__config__default_library_roots() {
  case "$PROJ/" in
    "$SHELLOPS_DIR"/*) __lint__config__shellops_library_roots ;;
    *) __lint__config__consumer_library_roots ;;
  esac
}

: <<'FUN'
Prints shellops' own library roots, lib and interpreter, as a struct array.
FUN
__lint__config__shellops_library_roots() {
  @arr lib interpreter
}

: <<'FUN'
Prints a consumer's library roots, the homes it keeps its shell in, as a
struct array: scripts, shell and src.
FUN
__lint__config__consumer_library_roots() {
  @arr scripts shell src
}

: <<'PUB_FUN'
Prints the names of the checks that run only under --added-only, as a struct
array; empty by default. A check goes here when the code already has findings
the team is working off: new lines still have to pass it, and a full sweep
leaves it out rather than failing on the old ones.
PUB_FUN
lint__config_added_only_checks() {
  @get "$1" '.added_only' "$(@arr)"
}

: <<'PUB_FUN'
Prints the directory, relative to the repository root, that holds the
repository's decision records; docs/decisions by default.
PUB_FUN
lint__config_decisions_folder() {
  @get "$1" '.decisions.folder' docs/decisions
}

: <<'PUB_FUN'
Prints the form the repository holds its decision records to: one-page, or
nothing when the repository names no form.
PUB_FUN
lint__config_decisions_form() {
  @get "$1" '.decisions.form' ''
}

: <<'PUB_FUN'
Prints how many words of prose a one-page decision record may spend, 450 by
default.
PUB_FUN
lint__config_decisions_page_words() {
  @get "$1" '.decisions.page_words' 450
}

: <<'PUB_FUN'
Prints how many digits a one-page decision record's number is written with,
6 by default.
PUB_FUN
lint__config_decisions_number_digits() {
  @get "$1" '.decisions.number_digits' 6
}

: <<'PUB_FUN'
Prints the pattern that names the CI component templates, relative to the
repository root; templates/*/template.yml by default. A yaml file it does
not match is not a template, and the template checks skip it.
PUB_FUN
lint__config_templates_glob() {
  @get "$1" '.templates.glob' 'templates/*/template.yml'
}

: <<'PUB_FUN'
Prints the base template's path, relative to the repository root: the one
template allowed to define before_script. Nothing by default, which holds
every template to the rule.
PUB_FUN
lint__config_templates_base() {
  @get "$1" '.templates.base' ''
}

: <<'PUB_FUN'
Prints the landing mark as the templates' rules spell it: the text every
rule that matches a merge-request pipeline must contain. Nothing by default,
which turns the job-lands-once check off.
PUB_FUN
lint__config_templates_mark() {
  @get "$1" '.templates.mark' ''
}

: <<'PUB_FUN'
Prints the templates that run on every push to a merge request, marked or
not, as a struct array of paths relative to the repository root; empty by
default. Governance checks and previews go here.
PUB_FUN
lint__config_templates_every_push() {
  @get "$1" '.templates.every_push' "$(@arr)"
}

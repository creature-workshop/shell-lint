#!/bin/sh

import \
  "$SHELLOPS_DIR/lib/git/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/api.sh" \
  "$SHELLOPS_DIR/lib/structs/api.sh"

: <<'MODULE'
Enforcement for a repository's decision records, the numbered markdown files
under the folder lint.json names, docs/decisions by default. What a record
is, by its path, is lib/markdown's to say (markdown__is_record).

A record's number is how every other file cites it, so a number belongs to one
record. Two branches that each take the next free number both look right until
the second one lands; the check here says so on the branch, by reading the
default branch as well as the working tree.

shell/lint/decisions/form.sh holds a record to the one-page form, in a
repository that asks for it, and shell/lint/decisions/_tables.sh holds the
tables such a record keeps beside it.
MODULE

__lint__decisions__AWK_DIR="$SHELL_LINT_DIR/shell/lint/decisions"

: <<'PUB_FUN'
Prints a finding for each of <files...> that is a decision record under PROJ
whose number another record carries: one beside it in the working tree, or one
the default branch has added since HEAD forked from it. A file that is not a
decision record is passed over. <opts>.config names the folder.

  lint__decisions__adr_number_is_unique "$(@obj)" docs/decisions/000034-a-climb.md
    ->  docs/decisions/000034-a-climb.md:1: number 000034 is taken by 000034-a-bundle.md
  lint__decisions__adr_number_is_unique "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:1: number 000007 is taken by 000007-singlets

Returns 0 when every number is its record's alone, 1 otherwise.

Usage: lint__decisions__adr_number_is_unique <opts> <files...>
PUB_FUN
lint__decisions__adr_number_is_unique() {
  __lint__decisions__adr_number_is_unique__folder="$(lint__decisions__folder "$1")"
  shift

  {
    __lint__decisions__taken_lines "$__lint__decisions__adr_number_is_unique__folder"
    println "$@" | __lint__decisions__tagged file
  } | lint__decisions__awk number_taken \
    -v folder="$__lint__decisions__adr_number_is_unique__folder" \
    >&2
}

: <<'PUB_FUN'
Prints the folder <opts>.config keeps the repository's decision records in,
relative to the repository root.

  lint__decisions__folder "$(@obj)"  ->  docs/decisions
PUB_FUN
lint__decisions__folder() {
  lint__config_decisions_folder "$(@get "$1" '.config' "$(@obj)")"
}

: <<'PUB_FUN'
Runs the decisions awk program <name> with the libraries it reads loaded
ahead of it: lib/path/paths.awk, and lib/markdown's lines.awk and records.awk
for what a line of markdown is and what a record's name and number are. The
arguments after <name> go to awk as they are.

Usage: lint__decisions__awk number_taken -v folder=docs/decisions
PUB_FUN
lint__decisions__awk() {
  __lint__decisions__awk__program="$1"
  shift

  awk \
    -f "$SHELLOPS_DIR/lib/path/paths.awk" \
    -f "$SHELLOPS_DIR/lib/markdown/lines.awk" \
    -f "$SHELLOPS_DIR/lib/markdown/records.awk" \
    -f "$__lint__decisions__AWK_DIR/$__lint__decisions__awk__program.awk" \
    "$@"
}

: <<'FUN'
Prints a "taken" line for every record under the folder <folder> that holds
its number: each one in PROJ's working tree, and each one the default branch
has added since HEAD forked from it.
FUN
__lint__decisions__taken_lines() {
  {
    find "$PROJ/$1" -name '*.md' 2>/dev/null
    GIT_REPO="$PROJ" git__added_upstream \
      "origin/$(GIT_REPO="$PROJ" git__default_branch)" \
      "$1"
  } | LC_ALL=C sort | __lint__decisions__tagged taken
}

: <<'FUN'
Reads paths on stdin and prints each as "<tag><TAB><path>".
FUN
__lint__decisions__tagged() {
  while IFS= read -r __lint__decisions__tagged__path; do
    printf '%s\t%s\n' "$1" "$__lint__decisions__tagged__path"
  done
}

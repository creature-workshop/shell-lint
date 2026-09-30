#!/bin/sh

import \
  "$SHELLOPS_DIR/lib/args/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/decisions/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/decisions/form.sh" \
  "$SHELLOPS_DIR/lib/markdown/api.sh" \
  "$SHELLOPS_DIR/lib/structs/api.sh"

: <<'FRAGMENT'
The tables of a one-page decision record, for a repository that names the
form (shell/lint/decisions/form.sh).

A table is a figure: a file of its own beside the record's adr.md, at
<folder>/<number>-<slug>/tables/<name>.md, and never a record. Its first line
is an H1, the table's title. A summary follows, saying why the table matters,
within a quarter to half of the page the record itself has. A "## Glossary"
section follows the summary, saying what each column means and what one row
is, and one Markdown table follows the glossary. The record beside the file
references every table file it holds as a link whose text is "Table <k>: "
and the table's title and whose target is tables/<name>.md, and keeps no
table of its own in a fenced block.

Each rule is a check of its own: the shape of a table file, and the record's
references. In a repository that names no form, both pass every file.
FRAGMENT

: <<'PUB_FUN'
Prints a finding for each part of the table shape a table file among
<files...> is missing: the H1, the summary within its budget, the glossary,
the one table after it. A file that is not a table file is passed over.

  lint__decisions__tables__shape "$opts" adrs/000007-fragments/tables/kinds.md
    ->  adrs/000007-fragments/tables/kinds.md:1: the summary is followed by a "## Glossary" section

Returns 0 when every table file has the shape, 1 otherwise.

Usage: lint__decisions__tables__shape <opts> <files...>
PUB_FUN
lint__decisions__tables__shape() {
  @is_true "$(lint__decisions__form__is_named "$1")" || return 0
  __lint__decisions__tables__shape__config="$(@get "$1" '.config' "$(@obj)")"
  __lint__decisions__tables__shape__folder="$(lint__decisions__folder "$1")"
  __lint__decisions__tables__shape__words="$(
    lint__config_decisions_page_words "$__lint__decisions__tables__shape__config"
  )"
  shift

  __lint__decisions__tables__shape_each \
    "$__lint__decisions__tables__shape__folder" \
    "$__lint__decisions__tables__shape__words" \
    "$@"
}

: <<'FUN'
Checks the shape of each table file among <files...> under <folder>, against
a page of <words> words. A file that is not a table file is passed over.
Returns 1 when any table file has a finding.

Usage: __lint__decisions__tables__shape_each <folder> <words> <files...>
FUN
__lint__decisions__tables__shape_each() {
  __lint__decisions__tables__shape_each__folder="$1"
  __lint__decisions__tables__shape_each__words="$2"
  shift 2

  __lint__decisions__tables__shape_each__status=0
  for __lint__decisions__tables__shape_each__file in "$@"; do
    __lint__decisions__tables__shape_one \
      "$__lint__decisions__tables__shape_each__folder" \
      "$__lint__decisions__tables__shape_each__words" \
      "$__lint__decisions__tables__shape_each__file" \
      || __lint__decisions__tables__shape_each__status=1
  done

  return "$__lint__decisions__tables__shape_each__status"
}

: <<'FUN'
Runs adr_table_shape.awk over <file> when it is a table file under <folder>,
against a page of <words> words, and sends what it prints to stderr. Any
other file passes.

Usage: __lint__decisions__tables__shape_one <folder> <words> <file>
FUN
__lint__decisions__tables__shape_one() {
  @is_true "$(markdown__is_table "$3" "$1")" || return 0

  lint__decisions__awk adr_table_shape \
    -v page_words="$2" \
    "$3" \
    >&2
}

: <<'PUB_FUN'
Prints a finding for each table file beside a record among <files...> that
the record does not reference as [Table <k>: <the table's title>](tables/<name>.md),
for each such link to no table file or with another text, and for each table
the record keeps in a fenced block. A table file among <files...> brings the
record beside it under check. A file that is neither is passed over.

  lint__decisions__tables__reference "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:1: the record references its table: [Table <k>: The kinds of change](tables/kinds.md)

Returns 0 when every record references its tables, 1 otherwise.

Usage: lint__decisions__tables__reference <opts> <files...>
PUB_FUN
lint__decisions__tables__reference() {
  @is_true "$(lint__decisions__form__is_named "$1")" || return 0
  __lint__decisions__tables__reference__folder="$(lint__decisions__folder "$1")"
  shift

  __lint__decisions__tables__reference__records="$(
    println "$@" \
      | __lint__decisions__tables__records_of "$__lint__decisions__tables__reference__folder"
  )"
  args__call_with_lines \
    __lint__decisions__tables__reference_each \
    "$__lint__decisions__tables__reference__records"
}

: <<'FUN'
Reads paths on stdin and prints, once each and sorted, the record each path
under <folder> belongs to: a record named adr.md is its own, and a table file
belongs to the adr.md beside its tables directory. Other paths print nothing.
FUN
__lint__decisions__tables__records_of() {
  while IFS= read -r __lint__decisions__tables__records_of__path; do
    __lint__decisions__tables__record_of "$1" "$__lint__decisions__tables__records_of__path"
  done | LC_ALL=C sort -u
}

: <<'FUN'
Prints the record <path> belongs to under <folder>: <path> itself when it is
a record named adr.md, the adr.md beside its tables directory when it is a
table file, nothing otherwise.
FUN
__lint__decisions__tables__record_of() {
  if @is_true "$(markdown__is_table "$2" "$1")"; then
    printf '%s/adr.md\n' "${2%/tables/*}"
  elif [ "${2##*/}" = adr.md ] && @is_true "$(markdown__is_record "$2" "$1")"; then
    println "$2"
  fi
}

: <<'FUN'
Checks the references of each record among <records...>. Returns 1 when any
record has a finding.
FUN
__lint__decisions__tables__reference_each() {
  __lint__decisions__tables__reference_each__status=0
  for __lint__decisions__tables__reference_each__record in "$@"; do
    __lint__decisions__tables__reference_one "$__lint__decisions__tables__reference_each__record" \
      || __lint__decisions__tables__reference_each__status=1
  done

  return "$__lint__decisions__tables__reference_each__status"
}

: <<'FUN'
Runs adr_table_reference.awk over the table files beside <record>, then
<record> itself when the file exists, and sends what it prints to stderr.
With nothing to read, prints nothing and returns 0.
FUN
__lint__decisions__tables__reference_one() {
  __lint__decisions__tables__reference_one__files="$(__lint__decisions__tables__files_beside "$1")"
  if [ -f "$1" ]; then
    __lint__decisions__tables__reference_one__files="$(
      printf '%s\n%s\n' "$__lint__decisions__tables__reference_one__files" "$1"
    )"
  fi
  @defined "$__lint__decisions__tables__reference_one__files" || return 0

  args__call_with_lines \
    lint__decisions__awk \
    "$__lint__decisions__tables__reference_one__files" \
    adr_table_reference \
    -v record="$1" \
    >&2
}

: <<'FUN'
Prints the table files beside <record>, sorted, one per line; nothing when
the record has no tables directory.
FUN
__lint__decisions__tables__files_beside() {
  find "${1%/adr.md}/tables" -name '*.md' 2>/dev/null | LC_ALL=C sort
}

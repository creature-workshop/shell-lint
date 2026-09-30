#!/bin/sh

import \
  "$SHELL_LINT_DIR/shell/lint/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/decisions/api.sh" \
  "$SHELLOPS_DIR/lib/markdown/api.sh" \
  "$SHELLOPS_DIR/lib/structs/api.sh"

: <<'FRAGMENT'
The one-page form of a decision record, for a repository that asks for it.

A repository opts in by naming the form in lint.json:

  { "decisions": { "folder": "adrs", "form": "one-page" } }

A one-page record's name carries its number padded to six digits, unless
lint.json says otherwise. It opens on the title "# ADR.<n>: <the decision>",
carrying its own number without leading zeros. Its header has Status, Date and
Merge request lines, and its status is approved or names the record that
superseded it. Its sections are Context, Decision and Consequences, in that
order. It cites another record as a link whose text is ADR.<n>@<repository>.
Its prose, from the Context heading to the end, fits a page: 450 words unless
lint.json says otherwise, with fenced examples and figure lines free.

Each part of the form is a check of its own, so a finding names the one rule a
record broke. In a repository that names no form, every check here passes
every file.
FRAGMENT

: <<'PUB_FUN'
Prints a finding for each part of the one-page shape a record among
<files...> is missing: the title carrying its number, the header lines, the
three sections in order.

  lint__decisions__form__shape "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:1: the header has no "- Date:" line

Returns 0 when every record has the shape, 1 otherwise.

Usage: lint__decisions__form__shape <opts> <files...>
PUB_FUN
lint__decisions__form__shape() {
  __lint__decisions__form__each adr_shape "$@"
}

: <<'PUB_FUN'
Prints a finding for each record among <files...> whose Status line says
anything but approved, or superseded by a linked record. A record is merged by
being approved, so one that says proposed is wrong the moment it lands.

  lint__decisions__form__status "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:3: the status is "approved", or "superseded by" and a link to the ADR that did

Returns 0 when every record's status stands, 1 otherwise.

Usage: lint__decisions__form__status <opts> <files...>
PUB_FUN
lint__decisions__form__status() {
  __lint__decisions__form__each adr_status "$@"
}

: <<'PUB_FUN'
Prints a finding for each record among <files...> whose number is not padded
to the width <opts>.config gives, six digits by default.

  lint__decisions__form__number_width "$opts" adrs/0007-fragments/adr.md
    ->  adrs/0007-fragments/adr.md:1: the record's number is written with 6 digits: 000007

Returns 0 when every record's number has the width, 1 otherwise.

Usage: lint__decisions__form__number_width <opts> <files...>
PUB_FUN
lint__decisions__form__number_width() {
  __lint__decisions__form__each adr_number_width "$@"
}

: <<'PUB_FUN'
Prints a finding for each citation of a decision record, in a record among
<files...>, that is not a link whose text is ADR.<n>@<repository>.

  lint__decisions__form__citations "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:22: link the citation: ADR.34@tool

Returns 0 when every citation is a link in that form, 1 otherwise.

Usage: lint__decisions__form__citations <opts> <files...>
PUB_FUN
lint__decisions__form__citations() {
  __lint__decisions__form__each adr_citations "$@"
}

: <<'PUB_FUN'
Prints a finding for each record among <files...> whose prose runs past the
page <opts>.config allows.

  lint__decisions__form__page "$opts" adrs/000007-fragments/adr.md
    ->  adrs/000007-fragments/adr.md:1: 512 words of prose; a page is 450

Returns 0 when every record fits its page, 1 otherwise.

Usage: lint__decisions__form__page <opts> <files...>
PUB_FUN
lint__decisions__form__page() {
  __lint__decisions__form__each adr_page "$@"
}

: <<'FUN'
Runs the awk program <program> over each of <files...> that is a decision
record, when <opts>.config names the one-page form, and sends what it prints
to stderr. Returns 1 when the program found anything in any record.

Usage: __lint__decisions__form__each <program> <opts> <files...>
FUN
__lint__decisions__form__each() {
  __lint__decisions__form__each__program="$1"
  __lint__decisions__form__each__config="$(@get "$2" '.config' "$(@obj)")"
  __lint__decisions__form__each__folder="$(lint__decisions__folder "$2")"
  @is_true "$(lint__decisions__form__is_named "$2")" || return 0
  shift 2

  __lint__decisions__form__each__words="$(
    lint__config_decisions_page_words "$__lint__decisions__form__each__config"
  )"
  __lint__decisions__form__each__digits="$(
    lint__config_decisions_number_digits "$__lint__decisions__form__each__config"
  )"
  __lint__decisions__form__each__status=0
  for __lint__decisions__form__each__file in "$@"; do
    __lint__decisions__form__each__record="$(markdown__is_record \
      "$__lint__decisions__form__each__file" \
      "$__lint__decisions__form__each__folder"
    )"
    @is_true "$__lint__decisions__form__each__record" || continue

    lint__decisions__awk "$__lint__decisions__form__each__program" \
      -v page_words="$__lint__decisions__form__each__words" \
      -v number_digits="$__lint__decisions__form__each__digits" \
      "$__lint__decisions__form__each__file" \
      >&2 \
      || __lint__decisions__form__each__status=1
  done

  return "$__lint__decisions__form__each__status"
}

: <<'PUB_FUN'
Prints true when <opts>.config names the one-page form, false when the
repository names no form.

  lint__decisions__form__is_named "$(@obj '.config.decisions.form' one-page)"  ->  true
  lint__decisions__form__is_named "$(@obj)"                                    ->  false

Usage: lint__decisions__form__is_named <opts>
PUB_FUN
lint__decisions__form__is_named() {
  __lint__decisions__form__is_named__config="$(@get "$1" '.config' "$(@obj)")"
  __lint__decisions__form__is_named__form="$(
    lint__config_decisions_form "$__lint__decisions__form__is_named__config"
  )"
  @succeeds test "$__lint__decisions__form__is_named__form" = one-page
}

#!/bin/sh

import \
  "$SHELL_LINT_DIR/shell/lint/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/checks/adrs/api.sh" \
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

Each part of the form is a check of its own under shell/lint/checks, so a
finding names the one rule a record broke, and each runs its detector
through lint__checks__adrs__form__check. In a repository that names no form,
every one of them passes every file.
FRAGMENT

: <<'PUB_FUN'
Runs the awk program at the path <program> over each of <files...> that is
a decision record, when <opts>.config names the one-page form, and sends
what it prints to stderr. Returns 1 when the program found anything in any
record. A form check's run role calls this with its own detector.

Usage: lint__checks__adrs__form__check <program> <opts> <files...>
PUB_FUN
lint__checks__adrs__form__check() {
  __lint__checks__adrs__form__check__program="$1"
  __lint__checks__adrs__form__check__config="$(@get "$2" '.config' "$(@obj)")"
  __lint__checks__adrs__form__check__folder="$(lint__checks__adrs__folder "$2")"
  @is_true "$(lint__checks__adrs__form__is_named "$2")" || return 0
  shift 2

  __lint__checks__adrs__form__check__words="$(
    lint__config__decisions_page_words "$__lint__checks__adrs__form__check__config"
  )"
  __lint__checks__adrs__form__check__digits="$(
    lint__config__decisions_number_digits "$__lint__checks__adrs__form__check__config"
  )"
  __lint__checks__adrs__form__check__status=0
  for __lint__checks__adrs__form__check__file in "$@"; do
    __lint__checks__adrs__form__check__record="$(markdown__is_record \
      "$__lint__checks__adrs__form__check__file" \
      "$__lint__checks__adrs__form__check__folder"
    )"
    @is_true "$__lint__checks__adrs__form__check__record" || continue

    lint__checks__adrs__awk "$__lint__checks__adrs__form__check__program" \
      -v page_words="$__lint__checks__adrs__form__check__words" \
      -v number_digits="$__lint__checks__adrs__form__check__digits" \
      "$__lint__checks__adrs__form__check__file" \
      >&2 \
      || __lint__checks__adrs__form__check__status=1
  done

  return "$__lint__checks__adrs__form__check__status"
}

: <<'PUB_FUN'
Prints true when <opts>.config names the one-page form, false when the
repository names no form.

  lint__checks__adrs__form__is_named "$(@obj '.config.decisions.form' one-page)"  ->  true
  lint__checks__adrs__form__is_named "$(@obj)"                                    ->  false

Usage: lint__checks__adrs__form__is_named <opts>
PUB_FUN
lint__checks__adrs__form__is_named() {
  __lint__checks__adrs__form__is_named__config="$(@get "$1" '.config' "$(@obj)")"
  __lint__checks__adrs__form__is_named__form="$(
    lint__config__decisions_form "$__lint__checks__adrs__form__is_named__config"
  )"
  @succeeds test "$__lint__checks__adrs__form__is_named__form" = one-page
}

#!/bin/sh

import \
  "$SHELLOPS_DIR/lib/args/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/api.sh" \
  "$SHELLOPS_DIR/lib/structs/api.sh"

: <<'MODULE'
Three lint checks on a catalog's CI component templates:

  - template-declares-inputs: every template starts with a spec.inputs block.
  - template-inherits-bootstrap: only the base template defines
    before_script; every other job extends the base job.
  - job-lands-once: a job runs once per merge request, in the landing run,
    unless its template is listed as one that runs on every push.

The checks read the catalog's facts from lint.json's `templates` block:
`glob` names the template files, `base` the base template, `mark` the
landing mark as the rules spell it, and `every_push` the templates that run
on every push. A yaml file `glob` does not match is not a template, and the
checks skip it.
MODULE

__lint__templates__AWK_DIR="$SHELL_LINT_DIR/shell/lint/templates"

: <<'PUB_FUN'
Reports each template in <files...> that has no spec.inputs block. The
finding is on line 1, since a missing block has no line of its own. Files
that are not templates are skipped.

  lint__templates__declares_inputs "$opts" templates/shell--lint/template.yml
    ->  templates/shell--lint/template.yml:1: no spec.inputs block; every template starts with one

Returns 0 when every template has the block, 1 otherwise.

Usage: lint__templates__declares_inputs <opts> <files...>
PUB_FUN
lint__templates__declares_inputs() {
  __lint__templates__declares_inputs__files="$(__lint__templates__select "$@")"
  __lint__templates__report declares_inputs "$__lint__templates__declares_inputs__files"
}

: <<'PUB_FUN'
Reports each job in <files...> that defines its own before_script. The base
template lint.json names is exempt; files that are not templates are
skipped.

  lint__templates__inherits_bootstrap "$opts" templates/shell--test/template.yml
    ->  templates/shell--test/template.yml:12: job '$[[ inputs.job-name ]]' defines before_script; remove it and extend the base job

Returns 0 when no job outside the base defines one, 1 otherwise.

Usage: lint__templates__inherits_bootstrap <opts> <files...>
PUB_FUN
lint__templates__inherits_bootstrap() {
  __lint__templates__inherits_bootstrap__base="$(lint__templates__base "$1")"
  __lint__templates__inherits_bootstrap__exempt="$(@arr "$__lint__templates__inherits_bootstrap__base")"
  __lint__templates__inherits_bootstrap__files="$(__lint__templates__select "$@")"
  __lint__templates__inherits_bootstrap__held="$(__lint__templates__without \
    "$__lint__templates__inherits_bootstrap__files" \
    "$__lint__templates__inherits_bootstrap__exempt"
  )"
  __lint__templates__report inherits_bootstrap "$__lint__templates__inherits_bootstrap__held"
}

: <<'PUB_FUN'
Reports each job in <files...> with a rule that matches a merge-request
pipeline without requiring the landing mark. Templates lint.json lists
under every_push are exempt; files that are not templates are skipped. When
lint.json names no mark, the check does nothing and returns 0.

  lint__templates__job_lands_once "$opts" templates/rust--test/template.yml
    ->  templates/rust--test/template.yml:38: job '$[[ inputs.job-name ]]' runs on every push: its rule matches merge_request_event without the mark 'scheduler\/next-merge'

Returns 0 when every job lands once, 1 otherwise.

Usage: lint__templates__job_lands_once <opts> <files...>
PUB_FUN
lint__templates__job_lands_once() {
  __lint__templates__job_lands_once__mark="$(lint__templates__mark "$1")"
  @defined "$__lint__templates__job_lands_once__mark" || return 0

  __lint__templates__job_lands_once__exempt="$(lint__templates__every_push "$1")"
  __lint__templates__job_lands_once__files="$(__lint__templates__select "$@")"
  __lint__templates__job_lands_once__held="$(__lint__templates__without \
    "$__lint__templates__job_lands_once__files" \
    "$__lint__templates__job_lands_once__exempt"
  )"
  CI_TEMPLATE_MARK="$__lint__templates__job_lands_once__mark" \
    __lint__templates__report job_lands_once "$__lint__templates__job_lands_once__held"
}

: <<'PUB_FUN'
Prints the template file pattern from <opts>.config, relative to the
repository root.

  lint__templates__glob "$(@obj)"  ->  templates/*/template.yml
PUB_FUN
lint__templates__glob() {
  lint__config_templates_glob "$(__lint__templates__config "$1")"
}

: <<'PUB_FUN'
Prints the base template's path from <opts>.config, relative to the
repository root, or nothing when lint.json names none.
PUB_FUN
lint__templates__base() {
  lint__config_templates_base "$(__lint__templates__config "$1")"
}

: <<'PUB_FUN'
Prints the landing mark from <opts>.config, spelled as the templates' rules
spell it, or nothing when lint.json names none.
PUB_FUN
lint__templates__mark() {
  lint__config_templates_mark "$(__lint__templates__config "$1")"
}

: <<'PUB_FUN'
Prints the templates <opts>.config lists as running on every push, as a
struct array of paths relative to the repository root.
PUB_FUN
lint__templates__every_push() {
  lint__config_templates_every_push "$(__lint__templates__config "$1")"
}

: <<'FUN'
Prints the lint.json settings in <opts>, or an empty object when the run
has none.
FUN
__lint__templates__config() {
  __lint__templates__config__none="$(@obj)"
  @get "$1" '.config' "$__lint__templates__config__none"
}

: <<'FUN'
Prints <path> relative to PROJ, with any leading ./ removed. Every path is
compared in this form, so a caller may spell one absolutely or relatively.
FUN
__lint__templates__key() {
  __lint__templates__key__path="${1#"$PROJ"/}"
  println "${__lint__templates__key__path#./}"
}

: <<'FUN'
Prints true when <path> exists and its relative form matches <glob>. The
pattern is a `case` pattern, so `*` also matches across directory
separators.
FUN
__lint__templates__is_template() {
  # shellcheck disable=SC2254 # the pattern is the point: it must glob, unquoted.
  case "$(__lint__templates__key "$1")" in
    $2)
      @succeeds [ -f "$1" ]
      ;;
    *)
      @false
      ;;
  esac
}

: <<'FUN'
Prints the templates among <files...>, one per line, in the order given:
the files that exist and match <opts>.config's pattern.

args:
  $1  The run's options
  $@  The files, after the options
FUN
__lint__templates__select() {
  __lint__templates__select__glob="$(lint__templates__glob "$1")"
  shift

  for __lint__templates__select__file in "$@"; do
    if @is_true "$(__lint__templates__is_template "$__lint__templates__select__file" "$__lint__templates__select__glob")"; then
      println "$__lint__templates__select__file"
    fi
  done
}

: <<'FUN'
Prints the lines of <files> whose relative form is not in the array
<exempt>, one per line.

args:
  $1  The files, one per line
  $2  The exempt paths (array)
FUN
__lint__templates__without() {
  args__call_with_lines __lint__templates__keep_unless_exempt "$1" "$2"
}

: <<'FUN'
Prints each of <files...> that the array <exempt> does not name, one per
line.

args:
  $1  The exempt paths (array)
  $@  The files, after the array
FUN
__lint__templates__keep_unless_exempt() {
  __lint__templates__keep_unless_exempt__exempt="$1"
  shift

  for __lint__templates__keep_unless_exempt__file in "$@"; do
    __lint__templates__keep_unless_exempt__key="$(__lint__templates__key "$__lint__templates__keep_unless_exempt__file")"
    if @is_false "$(@any __lint__templates__key_eq "$__lint__templates__keep_unless_exempt__exempt" "$__lint__templates__keep_unless_exempt__key")"; then
      println "$__lint__templates__keep_unless_exempt__file"
    fi
  done
}

: <<'FUN'
@any predicate: succeeds when the wrapped path $1 has the relative form $2.
FUN
__lint__templates__key_eq() {
  [ "$(__lint__templates__key "$(@unwrap "$1")")" = "$2" ]
}

: <<'FUN'
Runs the detector <name> over <files> in one awk and prints its findings.
Returns 0 when there are none, 1 otherwise. With no files the detector is
not run: an awk given no file reads stdin and waits.

args:
  $1  The detector's name under shell/lint/templates, without .awk
  $2  The files, one per line
FUN
__lint__templates__report() {
  @defined "$2" || return 0

  __lint__templates__report__hits="$(args__call_with_lines __lint__templates__awk "$2" "$1")"
  @defined "$__lint__templates__report__hits" || return 0

  println "$__lint__templates__report__hits"
  return 1
}

: <<'FUN'
Runs the detector <name> over <files...>, loading the shared scanner, the
yaml model and the document helpers before it.

args:
  $1  The detector's name
  $@  The files, after the name
FUN
__lint__templates__awk() {
  __lint__templates__awk__name="$1"
  shift

  awk \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$__lint__DIR/yaml_scan.awk" \
    -f "$__lint__templates__AWK_DIR/documents.awk" \
    -f "$__lint__templates__AWK_DIR/$__lint__templates__awk__name.awk" \
    "$@"
}

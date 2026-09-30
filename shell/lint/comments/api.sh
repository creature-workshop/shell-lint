#!/bin/sh

: <<'MODULE'
Enforcement for the shape of comments: where documentation lives, how much of it
there is, and what belongs in it. Ten checks share the scanners and the
doc-block classification because they all read the same thing -- the prose a
shell source carries about itself -- and differ only in what they object to.

Each check is a detector awk over shell-scan's scanner and doc_block.awk,
driven through one audit function.

The two prose-line caps below were measured over the 588 doc blocks in this
repository. Of 522 function docs, 516 sit at ten prose lines or fewer, four
reach eleven, and the remaining two jump straight to fourteen. Of 66 module
headers, 55 sit at ten or fewer, a handful run to sixteen, one reaches
twenty-four, and two run past it. Each cap is set in the gap the distribution
leaves, so it admits every block written the way the rest of them are and
catches only the ones that broke away. A header gets twice the allowance
because it introduces a whole file rather than one function.
MODULE

import \
  "$SHELLOPS_DIR/lib/git/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/api.sh"

# CONST: The directory of the awk programs, absolute so the caller's cwd does not matter.
__lint__comments__DIR="$SHELL_LINT_DIR/shell/lint/comments"

# CONST: The scanner runtime every program is loaded with; it tracks the heredocs.
__lint__comments__RUNTIME="$SHELL_SCAN_DIR/shell/scan/scan.awk"

# CONST: The most prose lines a function's doc block may run to.
__lint__comments__FUNC_DOC_CAP=12

# CONST: The most prose lines a module's doc block may run to.
__lint__comments__MODULE_DOC_CAP=24

: <<'FUN'
Prints every finding the detector __lint__comments__audit named reports in
<files...>, as "<file>:<lineno>: <why>", every file in one awk.

Both caps and the repository root are passed to every detector rather than
only to the ones that read them, so the invocation is the same shape whichever
check is running.
FUN
__lint__comments__scan_files() {
  awk \
    -v func_cap="$__lint__comments__FUNC_DOC_CAP" \
    -v header_cap="$__lint__comments__MODULE_DOC_CAP" \
    -v root="$PROJ" \
    -v library_roots="$__lint__comments__audit__roots" \
    -f "$__lint__comments__RUNTIME" \
    -f "$SHELL_LINT_DIR/shell/lint/library_root.awk" \
    -f "$__lint__comments__DIR/doc_block.awk" \
    -f "$__lint__comments__DIR/$__lint__comments__audit__detector" \
    "$@"
}

: <<'FUN'
  Runs <detector> over <files...>, printing every offender it finds rather than
  stopping at the first.

  Usage: __lint__comments__audit <detector> <opts> <files...>

  The library roots a detector keys a file by come from the options' config,
  or the defaults.

  Returns 0 when every file is clean, 1 otherwise.
FUN
__lint__comments__audit() {
  __lint__comments__audit__detector="$1"
  __lint__comments__audit__roots="$(@join "$(lint__config_library_roots "$(@get "$2" '.config' "$(@obj)")")" ' ')"
  shift 2

  __lint__comments__audit__hits="$(lint__call_with_existing __lint__comments__scan_files "$@")"
  @defined "$__lint__comments__audit__hits" || return 0

  log "$__lint__comments__audit__hits"
  return 1
}

: <<'PUB_FUN'
  Rejects an entrypoint that documents itself twice: a doc block above the code
  as well as the usage its --help prints. The usage is the file doc -- the same
  subject, addressed to the reader who asked for it -- so the second copy has no
  audience of its own and only drifts from the first.

  Every file is a candidate; carrying a usage is what makes one an entrypoint,
  so a file without one has nothing to duplicate and passes on that account.

  Delete the top-of-file block. The usage already is the file doc; nothing in
  the second copy is needed once that is so.

  Usage: lint__comments__comment_lint_no_duplicate_file_doc <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if no entrypoint carries both, 1 otherwise (offenders printed to
  stderr).
PUB_FUN
lint__comments__comment_lint_no_duplicate_file_doc() {
  __lint__comments__audit duplicate_file_doc.awk "$@"
}

: <<'PUB_FUN'
  Rejects a doc block whose prose outgrows what a doc is for. Only prose counts:
  blank lines, labelled sections, and the indented content beneath them are as
  long as the interface they describe, and a cap on those would be a cap on
  documenting an interface properly.

  Usage: lint__comments__comment_lint_no_oversized_doc_block <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if every block is within its cap, 1 otherwise (offenders printed to
  stderr).
PUB_FUN
lint__comments__comment_lint_no_oversized_doc_block() {
  __lint__comments__audit oversized_doc_block.awk "$@"
}

: <<'PUB_FUN'
  Rejects comment prose written about the code's past. A comment describes what
  the code does now -- the reader has the current file and nothing else, so a
  sentence about an earlier shape sends them hunting for something that is not
  there. Doc blocks and `#` comments are both prose; heredoc data is not.

  Usage: lint__comments__comment_lint_no_backward_reference <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if no comment looks backward, 1 otherwise (offenders printed to
  stderr).
PUB_FUN
lint__comments__comment_lint_no_backward_reference() {
  __lint__comments__audit backward_reference.awk "$@"
}

: <<'PUB_FUN'
  Rejects a work-tracker marker inside a doc block. A doc block states a
  contract, and someone reading it to learn what the unit promises is not the
  audience for work that has not happened yet. Beside a line of code the same
  marker is fine: there it addresses whoever edits that line.

  Usage: lint__comments__comment_lint_no_doc_block_tracker <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if no doc block carries one, 1 otherwise (offenders printed to
  stderr).
PUB_FUN
lint__comments__comment_lint_no_doc_block_tracker() {
  __lint__comments__audit doc_block_tracker.awk "$@"
}

: <<'PUB_FUN'
  Rejects a library file whose file doc is not labelled for its importers, a
  MODULE or FRAGMENT label on any block but a file doc, and an import of a
  FRAGMENT from outside its module. The label is what the lowering keys on to
  place the doc in the tree (ADR 000039), so a wrong one puts the file's doc on
  the wrong node; a fragment reached from another directory is the private
  reach ADR 000031 names.

  Only the files given are read, so an import from a file outside them is seen
  in the full sweep and not in a narrower run.

  Usage: lint__comments__comment_lint_file_label <opts> <files...>

  <opts> is the run's options object; this check reads the library roots
  from its config, or the defaults.

  Returns 0 if every file doc carries its label and no fragment is reached from
  outside, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__comments__comment_lint_file_label() {
  __lint__comments__audit file_label.awk "$@"
}

: <<'PUB_FUN'
  Rejects a usage heredoc that does not open on HELP, and a HELP heredoc that
  is not the usage. Carrying a HELP heredoc is what marks a file as an
  entrypoint (ADR 000039), so the label goes on the usage and on nothing else.

  Usage: lint__comments__comment_lint_usage_label <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if every usage opens on HELP and nothing else does, 1 otherwise
  (offenders printed to stderr).
PUB_FUN
lint__comments__comment_lint_usage_label() {
  __lint__comments__audit usage_label.awk "$@"
}

: <<'PUB_FUN'
  Rejects a function doc whose label does not say what the function is to its
  callers: PUB_FUN for a library module's public surface, FUN for a private
  function, a plugin's role, or any function of an entrypoint. The label is
  what the lowering reads for the function's visibility (ADR 000039), so it
  has to agree with the name ADR 000031 gives the function, and a PUB_FUN or
  FUN on a block that documents no function is a finding too.

  Usage: lint__comments__comment_lint_function_label <opts> <files...>

  <opts> is the run's options object; this check reads the library roots
  from its config, or the defaults.

  Returns 0 if every function doc carries the label its name earns, 1
  otherwise (offenders printed to stderr).
PUB_FUN
lint__comments__comment_lint_function_label() {
  __lint__comments__audit function_label.awk "$@"
}

: <<'PUB_FUN'
  Rejects a doc above a module-root variable or constant whose label does not
  say what the name is: CONST when the name's last segment is upper case, VAR
  otherwise, with PUB_ in a library file when the name has no leading __
  (ADR 000031). The label is what the lowering reads for the name's kind and
  visibility (ADR 000039), so it has to agree with the name, and one of the
  four labels on a block that documents no root assignment is a finding too.

  Usage: lint__comments__comment_lint_assignment_label <opts> <files...>

  <opts> is the run's options object; this check reads the library roots
  from its config, or the defaults.

  Returns 0 if every such doc carries the label its name earns, 1 otherwise
  (offenders printed to stderr).
PUB_FUN
lint__comments__comment_lint_assignment_label() {
  __lint__comments__audit assignment_label.awk "$@"
}

: <<'PUB_FUN'
  Rejects a # comment addressed to a reader anywhere but above a module-root
  constant or variable, and one there that does not lead with the label its
  name earns (ADR 000040). Inside a function body a comment is a finding: what
  it says belongs in the function's doc, or the function splits. A line a tool
  reads, a shellcheck directive or a check's allow marker, is never one.

  Usage: lint__comments__comment_lint_inline_comment <opts> <files...>

  <opts> is the run's options object; this check reads the library roots
  from its config, or the defaults.

  Returns 0 if every reader-facing comment sits where it may and leads as it
  must, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__comments__comment_lint_inline_comment() {
  __lint__comments__audit inline_comment.awk "$@"
}

: <<'PUB_FUN'
  Rejects a doc block opener or a typed comment with no blank line above it,
  so the eye finds where the entry above ends. The first line of a file and a
  doc below a `#` line, a directive say, need none.

  Usage: lint__comments__comment_lint_doc_spacing <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Returns 0 if every doc sits below a blank line, 1 otherwise (offenders
  printed to stderr).
PUB_FUN
lint__comments__comment_lint_doc_spacing() {
  __lint__comments__audit doc_spacing.awk "$@"
}

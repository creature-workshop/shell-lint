#!/bin/sh

: <<'MODULE'
API for linting and formatting checks.

Note: structs API enforcement (rejecting raw jq/opx) lives with the module it
polices, in shellops' lib/structs/lint/api.sh.
MODULE

import \
  "$SHELLOPS_DIR/lib/git/api.sh" \
  "$SHELL_LINT_DIR/shell/lint/config.sh"

: <<'CONST'
Absolute path to this module's directory so the awk scanners resolve
regardless of the caller's cwd.
CONST
__lint__DIR="$SHELL_LINT_DIR/shell/lint"

: <<'PUB_FUN'
Calls <fn> with the files among <paths...> that exist, in their order, so a
scanner runs once over every file rather than once per file. A path that is
not a file is dropped, as a single-file scan drops it. With no file left,
<fn> is not called at all: an awk given no file reads stdin and waits.

Usage: lint__call_with_existing <fn> <paths...>
PUB_FUN
lint__call_with_existing() {
  __lint__call_with_existing__fn="$1"
  shift
  __lint__call_with_existing__count=$#
  __lint__call_with_existing__i=0
  while [ "$__lint__call_with_existing__i" -lt "$__lint__call_with_existing__count" ]; do
    if [ -f "$1" ]; then
      set -- "$@" "$1"
    fi
    shift
    __lint__call_with_existing__i=$((__lint__call_with_existing__i + 1))
  done

  [ "$#" -gt 0 ] || return 0
  "$__lint__call_with_existing__fn" "$@"
}

: <<'PUB_FUN'
  Line-level indentation check for shell sources, backed by
  shell/lint/indent_scan.awk (which exempts heredoc bodies, so doc-comments and
  embedded usage text are never policed).

  <opts>.config is the repository's lint.json: its `indent.width` is the
  required leading-space multiple (2 by default) and `indent.tabs` whether
  leading tabs are allowed (false by default). Trailing whitespace is always
  rejected.

  Usage: lint__indent <opts> <files...>

  Returns 0 when every file is clean, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__indent() {
  __lint__indent__config="$(@get "$1" '.config' "$(@obj)")"
  __lint__indent__width="$(lint__config_indent_width "$__lint__indent__config")"
  __lint__indent__tabs="$(lint__config_allow_tabs "$__lint__indent__config")"
  __lint__indent__allow_tabs="$(__lint__awk_flag "$__lint__indent__tabs")"
  shift

  __lint__indent__hits="$(lint__call_with_existing __lint__indent_scan "$@")"
  @defined "$__lint__indent__hits" || return 0

  log "$__lint__indent__hits"
  return 1
}

: <<'FUN'
Scans <files...> in one awk for indentation findings, at the width and tab
policy lint__indent read from the config. scan.awk, from shell-scan, is the
shared scanner runtime (heredoc tracking and the note emitter).
FUN
__lint__indent_scan() {
  awk \
    -v width="$__lint__indent__width" \
    -v allow_tabs="$__lint__indent__allow_tabs" \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$__lint__DIR/indent_scan.awk" \
    "$@"
}

: <<'FUN'
Scans whole files, in one awk, for function # doc-blocks.
FUN
__lint__doc_scan_files() {
  awk \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$__lint__DIR/doc_comment_scan.awk" \
    "$@"
}

: <<'FUN'
Print the staged blob at <path>, where <path> is how the index spells it.
FUN
__lint__doc_index_blob() {
  git -C "$PROJ" show ":$1"
}

: <<'FUN'
Run <scanner> over a staged blob, reporting only findings on the given added
line numbers. <fname> is the path printed in those findings.

Usage: __lint__doc_scan_blob <fname> <added-csv> <blob> <scanner>
FUN
__lint__doc_scan_blob() {
  println "$3" \
    | awk \
      -v fname="$1" \
      -v added="$2" \
      -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
      -f "$4" \
      -
}

: <<'FUN'
Scans the staged version of <file>, reporting only blocks whose first line was
added in the staged diff -- the --added-only mode.
FUN
__lint__doc_scan_staged() {
  __lint__doc_scan_staged__added="$(git__staged_added_lines "$1")"
  @defined "$__lint__doc_scan_staged__added" || return 0
  __lint__doc_scan_staged__added="$(
    printf '%s' "$__lint__doc_scan_staged__added" \
      | tr '\n' ','
  )"

  __lint__doc_scan_staged__indexed="$(git__index_path "$1")"
  __lint__doc_scan_staged__blob="$(
    __lint__doc_index_blob "$__lint__doc_scan_staged__indexed"
  )"

  __lint__doc_scan_blob \
    "$1" \
    "$__lint__doc_scan_staged__added" \
    "$__lint__doc_scan_staged__blob" \
    "$__lint__DIR/doc_comment_scan.awk"
}

: <<'PUB_FUN'
  Flags multi-line `#` comment doc-blocks that document a function -- a run of
  two or more `#` comment lines immediately above a function definition -- which
  the shell house style requires to be heredoc doc blocks, `: <<'PUB_FUN'` or
  `: <<'FUN'` per the function-label check.
  Heredoc bodies are exempt; a `# doc-comment-check: allow` marker on a block,
  or within three lines above it, exempts it.

  <opts> is an options object (see @obj). With `.added_only` true, only blocks
  whose first line was added in the staged diff are flagged -- the pre-commit
  mode that polices new code without blocking on the pre-existing backlog.

  Usage: lint__doc_comments <opts> <files...>

  Returns 0 when every file is clean, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__doc_comments() {
  __lint__doc_comments__opts="$1"
  shift
  __lint__doc_comments__added_only="$(@option "$__lint__doc_comments__opts" 'added_only' false)"

  if @is_true "$__lint__doc_comments__added_only"; then
    __lint__doc_comments__hits="$(__lint__doc_scan_each_staged "$@")"
  else
    __lint__doc_comments__hits="$(lint__call_with_existing __lint__doc_scan_files "$@")"
  fi
  @defined "$__lint__doc_comments__hits" || return 0

  log "$__lint__doc_comments__hits"
  return 1
}

: <<'FUN'
Prints the staged-diff findings of every file in <files...>, one file's
staged blob per awk since each is read from the index rather than the tree.
FUN
__lint__doc_scan_each_staged() {
  for __lint__doc_scan_each_staged__file in "$@"; do
    __lint__doc_scan_staged "$__lint__doc_scan_each_staged__file"
  done
}

: <<'PUB_FUN'
  Flags awk that breaks the house style: an `if`/`else`/`for`/`while` body
  without braces, a wide-gap local parameter, or an unprefixed parameter that
  sits after a local. Pattern-action rules and fence/container globals are not
  findings. The scanner skips strings, regexes, and `#` comments; it is
  conservative and will miss a rare site rather than flag a literal.

  Usage: lint__awk_style <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Every finding in every file is reported before the non-zero return.
  Returns 0 when every file is clean, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__awk_style() {
  shift
  __lint__awk_style__hits="$(lint__call_with_existing __lint__awk_style_scan "$@")"
  @defined "$__lint__awk_style__hits" || return 0

  log "$__lint__awk_style__hits"
  return 1
}

: <<'FUN'
Scans <files...> in one awk for awk house-style findings.
FUN
__lint__awk_style_scan() {
  awk \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$__lint__DIR/awk_lex.awk" \
    -f "$__lint__DIR/awk_style_scan.awk" \
    "$@"
}

: <<'PUB_FUN'
  Flags an awk program that exits with an answer while it has input left to
  read: a bare `exit`, `exit 0` or `exit <expression>` outside BEGIN and END.
  Such a reader closes the pipe on a writer still writing, and under pipefail
  the writer's SIGPIPE fails the pipeline with 141 now and then, whatever the
  answer was. An error exit, `exit` with a non-zero number, is not a finding,
  and neither is an exit below `# early-exit-check: allow`.

  Usage: lint__awk_early_exit <opts> <files...>

  <opts> is the run's options object; this check reads nothing from it.

  Every finding in every file is reported before the non-zero return.
  Returns 0 when every file is clean, 1 otherwise (offenders printed to stderr).
PUB_FUN
lint__awk_early_exit() {
  shift
  __lint__awk_early_exit__hits="$(lint__call_with_existing __lint__awk_early_exit_scan "$@")"
  @defined "$__lint__awk_early_exit__hits" || return 0

  log "$__lint__awk_early_exit__hits"
  return 1
}

: <<'FUN'
Scans <files...> in one awk for exits that leave input unread.
FUN
__lint__awk_early_exit_scan() {
  awk \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$__lint__DIR/awk_lex.awk" \
    -f "$__lint__DIR/awk_early_exit.awk" \
    "$@"
}

: <<'FUN'
Echoes 1 for the boolean true and 0 for anything else -- the form the scanners
take a flag in through -v.
FUN
__lint__awk_flag() {
  case "$1" in
    true) echo 1 ;;
    *) echo 0 ;;
  esac
}

: <<'PUB_FUN'
  Checks Go files for formatting issues using gofmt.

  Usage: lint__go [files...]

  If no files are provided, checks all Go files under go/.
  Returns 0 if all files are formatted, 1 otherwise.
PUB_FUN
lint__go() {
  __lint__go__repo_root="$(git rev-parse --show-toplevel)"

  if [ "$#" -eq 0 ]; then
    set -- "$__lint__go__repo_root/go/"
  fi

  __lint__go__unformatted="$(gofmt -l "$@" 2>/dev/null || true)"

  if @defined "$__lint__go__unformatted"; then
    echo "The following Go files need formatting:"
    echo "$__lint__go__unformatted"
    echo ""
    echo "Run 'gofmt -w go/' to fix."
    return 1
  fi

  return 0
}

: <<'PUB_FUN'
  Checks Rust files for formatting issues using rustfmt.

  Usage: lint__rust

  Checks all Rust files in the crates workspace.
  Returns 0 if all files are formatted, 1 otherwise.
PUB_FUN
lint__rust() {
  __lint__rust__repo_root="$(git rev-parse --show-toplevel)"

  if ! cargo fmt --manifest-path "$__lint__rust__repo_root/crates/Cargo.toml" --all -- --check; then
    echo ""
    echo "Run 'cargo fmt --manifest-path crates/Cargo.toml --all' to fix."
    return 1
  fi

  return 0
}

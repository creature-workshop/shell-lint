#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/api.sh"

: <<'MODULE'
A public name in a library file begins with that file's module path.
MODULE

: <<'PUB_FUN'
Prints each public definition in <files...> that does not begin with the
file's module path. A library file's module path is the directories under
its library root, the ones the options' config names or the defaults,
joined by __, and api is never a segment of it. A name that begins with __
is private, and one that begins with @ is a role.

Usage: lint__public_name <opts> <files...>
PUB_FUN
lint__public_name() {
  __lint__public_name__roots="$(@join "$(lint__config_library_roots "$(@get "$1" '.config' "$(@obj)")")" ' ')"
  shift
  __lint__public_name__hits="$(lint__call_with_existing __lint__public_name__scan "$@")"
  @defined "$__lint__public_name__hits" || return 0

  log "$__lint__public_name__hits"
  return 1
}

: <<'FUN'
Scans <files...> for a public definition outside its module path.
FUN
__lint__public_name__scan() {
  awk \
    -v root="$PROJ" \
    -v library_roots="$__lint__public_name__roots" \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/library_root.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/name_prefix.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/public_name.awk" \
    "$@"
}

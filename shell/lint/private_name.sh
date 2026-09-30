#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/api.sh"

: <<'MODULE'
A private name in a library file is fully qualified: a function or a
constant begins with the module path, so a caller outside the module cannot
spell it, and a function's variable begins with the module path and then the
function's own name, so no two functions can collide.
MODULE

: <<'PUB_FUN'
Prints each private name in <files...> that is not fully qualified. A
library file's module path is the directories under its library root, the
ones the options' config names or the defaults, joined by __, and the
barrel's stem, api, is never a segment of it. A variable assigned in a
function begins with __<module>__<function>__, the function's own name once
the module's spelling is dropped; a plugin role's begins with
__<plugin>_<role>__. A variable read in a function may be any of the
module's.

Usage: lint__private_name <opts> <files...>
PUB_FUN
lint__private_name() {
  __lint__private_name__roots="$(@join "$(lint__config_library_roots "$(@get "$1" '.config' "$(@obj)")")" ' ')"
  shift
  __lint__private_name__hits="$(lint__call_with_existing __lint__private_name__scan "$@")"
  @defined "$__lint__private_name__hits" || return 0

  log "$__lint__private_name__hits"
  return 1
}

: <<'FUN'
Scans <files...> for a private name outside its module path.
FUN
__lint__private_name__scan() {
  awk \
    -v root="$PROJ" \
    -v library_roots="$__lint__private_name__roots" \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/library_root.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/name_prefix.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/scope.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/words.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/private_name.awk" \
    "$@"
}

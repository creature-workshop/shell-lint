#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/api.sh"

: <<'FRAGMENT'
A file imported only by its own module is named with a leading _.
FRAGMENT

: <<'PUB_FUN'
Prints each library file in <files...> that is imported only from its own
directory and whose name does not begin with _. A file nothing imports is
not judged. A plugin, a template and an entrypoint are not judged.

Usage: lint__private_file <opts> <files...>

The library roots come from the options' config, or the defaults.
PUB_FUN
lint__private_file() {
  __lint__private_file__roots="$(@join "$(lint__config_library_roots "$(@get "$1" '.config' "$(@obj)")")" ' ')"
  shift
  __lint__private_file__hits="$(lint__call_with_existing __lint__private_file__scan "$@")"
  @defined "$__lint__private_file__hits" || return 0

  log "$__lint__private_file__hits"
  return 1
}

: <<'FUN'
Scans <files...> for a private file whose name does not begin with _.
FUN
__lint__private_file__scan() {
  awk \
    -v root="$PROJ" \
    -v library_roots="$__lint__private_file__roots" \
    -f "$SHELL_SCAN_DIR/shell/scan/scan.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/library_root.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/name_prefix.awk" \
    -f "$SHELL_LINT_DIR/shell/lint/private_file.awk" \
    "$@"
}

#!/usr/bin/env bash
# Fixture: a clean shell source for the indentation gate's bats tests. It is
# deliberately discovered by the live gate too, dogfooding two properties --
# the exploded $( ... ) invocation form passes, and heredoc bodies (which align
# prose freely) are never policed.

set -euo pipefail

: <<'DOC'
Heredoc body whose prose is aligned to odd columns on purpose:
  --flag      what it does, with the continuation wrapped onto a second line
              that lands on an odd leading-space count the gate must ignore
  --other     another option documented the same way
DOC

collect() {
  __collect__names="$(printf '%s\n' \
    "ada" \
    "alan" \
    "grace" \
  )"
  printf '%s\n' "$__collect__names"
}

main() {
  case "${1:-}" in
    list) collect ;;
    *)    collect ;;
  esac
}

#!/usr/bin/env bash

: <<'DOC'
Running a command with bats' DEBUG trap off.
DOC

: <<'DOC'
Run "$@" with bats' DEBUG trap and functrace off, then restore both and pass
the command's exit status through.

bats installs bats_debug_trap under `set -T` so a failure can report a stack
trace, which makes every command in every sourced file pay the trap. Loading a
library is not a step anyone traces, and the tax dwarfs the work: the
build-release action sources in 21ms on its own and 285ms under the trap. Both
are back in place when this returns, so a failure in the test body still
reports its trace.

  untraced source "$SHELLOPS_DIR/actions/render"
  untraced import "$SHELLOPS_DIR/lib/pandoc/fixtures.sh"
DOC
untraced() {
  __untraced__trap="$(trap -p DEBUG)"
  __untraced__flags="$-"
  __untraced__status=0

  trap - DEBUG
  set +T
  "$@" || __untraced__status=$?

  case "$__untraced__flags" in
    *T*) set -T ;;
  esac
  eval "$__untraced__trap"

  return "$__untraced__status"
}

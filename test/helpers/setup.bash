#!/usr/bin/env bash

bats_require_minimum_version 1.5.0

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_LINT_DIR="$(cd "$TEST_DIR/.." && pwd)"
export SHELL_LINT_DIR
export SHELLOPS_DIR="${SHELLOPS_DIR:-$SHELL_LINT_DIR/shell/.ops}"
export SHELL_SCAN_DIR="${SHELL_SCAN_DIR:-$SHELL_LINT_DIR/shell/.scan}"
export PROJ="$TEST_DIR"

source "$TEST_DIR/helpers/untraced.bash"

untraced source "$SHELLOPS_DIR/.envrc"

untraced load "$SHELLOPS_DIR/test/lib/bats-support/load.bash"
untraced load "$SHELLOPS_DIR/test/lib/bats-assert/load.bash"

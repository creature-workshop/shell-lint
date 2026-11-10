#!/usr/bin/env bash

bats_require_minimum_version 1.5.0

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKOUT_DIR="$(cd "$TEST_DIR/.." && pwd)"
export SHELL_LINT_DIR="$CHECKOUT_DIR"
export SHELLOPS_DIR="${SHELLOPS_DIR:-$CHECKOUT_DIR/shell/.ops}"
export SHELL_SCAN_DIR="${SHELL_SCAN_DIR:-$CHECKOUT_DIR/shell/.scan}"
export PROJ="$TEST_DIR"
SCAN_DIR="$SHELL_SCAN_DIR"

source "$TEST_DIR/helpers/untraced.bash"

untraced source "$SHELLOPS_DIR/.envrc"

# shellops' .envrc exports SHELL_LINT_DIR and SHELL_SCAN_DIR again, as the
# trees its own lock pins. The suites test this checkout, so both go back to
# the values set above.
export SHELL_LINT_DIR="$CHECKOUT_DIR"
export SHELL_SCAN_DIR="$SCAN_DIR"

untraced load "$SHELLOPS_DIR/test/lib/bats-support/load.bash"
untraced load "$SHELLOPS_DIR/test/lib/bats-assert/load.bash"
source "$SHELLOPS_DIR/test/helpers/printing.bash"

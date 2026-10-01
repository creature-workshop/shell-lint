#!/usr/bin/env bats
# Covers the usage-label check through its run function, over fixtures written
# for each case.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/shell/usage-label/api.sh"

  # The fixtures are shellops-shaped, under lib/ and interpreter/, and those
  # are library roots only when the options name them, as shellops' own
  # lint.json does.
  SHELLOPS_ROOTS="$(@obj '.config' "$(@obj '.library_roots' "$(@arr lib interpreter)")")"
}

@test "usage label: flags a USAGE heredoc that opens on EOF" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<EOF
Usage: ops lint [files...]
EOF
)"

main() {
  log "$USAGE"
}
FIX
)"

  run lint__checks__shell__usage_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "cli/lint:3:"
  assert_output --partial "opens on EOF"
}

@test "usage label: accepts HELP on the USAGE heredoc" {
  __f="$(fixture cli/lint <<'FIX'
#!/usr/bin/env bash

USAGE="$(cat <<HELP
Usage: ops lint [files...]
HELP
)"

main() {
  cat <<EOF
$USAGE
EOF
}
FIX
)"

  run lint__checks__shell__usage_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_success
  assert_output ""
}

@test "usage label: flags HELP on a heredoc that is not the usage" {
  __f="$(fixture lib/releases/api.sh <<'FIX'
#!/bin/sh

release_body() {
  cat <<HELP
Released.
HELP
}
FIX
)"

  run lint__checks__shell__usage_label__run "$SHELLOPS_ROOTS" "$__f"
  assert_failure
  assert_output --partial "lib/releases/api.sh:4:"
  assert_output --partial "not assigned to USAGE"
}


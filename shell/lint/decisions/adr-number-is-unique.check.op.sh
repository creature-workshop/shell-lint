#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/decisions/api.sh"

:<<'DOC'
The adr-number-is-unique check: one lint check plugin. See
shell/lint/registry.sh for what the roles mean.
DOC
@check.adr-number-is-unique() {
  @summary() {
    println "An ADR's number is unique: no record beside it, and none the default branch has added, carries the same one."
  }

  @languages() {
    @arr markdown
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Give the flagged record the next number no record holds, here or on the" \
      "default branch, and update every citation of it to match."
  }

  @run() {
    lint__decisions__adr_number_is_unique "$@"
  }
}

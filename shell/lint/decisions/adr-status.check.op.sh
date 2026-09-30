#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/decisions/form.sh"

:<<'DOC'
The adr-status check: one lint check plugin. See
shell/lint/registry.sh for what the roles mean, and shell/lint/decisions/form.sh
for the one-page form and how a repository asks for it.
DOC
@check.adr-status() {
  @summary() {
    println "A one-page ADR's status is approved, or names the ADR that superseded it; a record is never merged as proposed."
  }

  @languages() {
    @arr markdown
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Write \"- Status: approved\" from the first draft: the merge that lands the record is its" \
      "approval, and a record that is not approved never reaches the default branch."
  }

  @run() {
    lint__decisions__form__status "$@"
  }
}

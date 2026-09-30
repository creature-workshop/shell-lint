#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/decisions/form.sh"

:<<'DOC'
The adr-page check: one lint check plugin. See
shell/lint/registry.sh for what the roles mean, and shell/lint/decisions/form.sh
for the one-page form and how a repository asks for it.
DOC
@check.adr-page() {
  @summary() {
    println "A one-page ADR's prose fits its page, counted from the Context heading to the end; fenced examples and figure lines are free."
  }

  @languages() {
    @arr markdown
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Cut the record to one decision: the research, the alternatives at length and the plan" \
      "belong in the design document or ticket the header links, not on the page."
  }

  @run() {
    lint__decisions__form__page "$@"
  }
}

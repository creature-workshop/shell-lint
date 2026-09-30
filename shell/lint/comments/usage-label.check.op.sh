#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/comments/api.sh"

:<<'DOC'
The usage-label check: one lint check plugin. See shell/lint/registry.sh for
what the roles mean.
DOC
@check.usage-label() {
  @summary() {
    println "An entrypoint's usage heredoc opens on HELP, and HELP names nothing else."
  }

  @languages() {
    @arr shell
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Open the heredoc assigned to USAGE on the terminator HELP, and give any" \
      "other heredoc a different one."
  }

  @run() {
    lint__comments__comment_lint_usage_label "$@"
  }
}

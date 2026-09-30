#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/comments/api.sh"

:<<'DOC'
The backward-reference check: one lint check plugin. See shell/lint/registry.sh
for what the roles mean.
DOC
@check.backward-reference() {
  @summary() {
    println "Comment prose describes what the code does now, never what it used to do."
  }

  @languages() {
    @arr shell
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Rewrite the sentence in the present tense; the change itself belongs in" \
      "the commit message."
  }

  @run() {
    lint__comments__comment_lint_no_backward_reference "$@"
  }
}

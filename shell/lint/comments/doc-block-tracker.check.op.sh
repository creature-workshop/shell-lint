#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/comments/api.sh"

:<<'DOC'
The doc-block-tracker check: one lint check plugin. See shell/lint/registry.sh
for what the roles mean.
DOC
@check.doc-block-tracker() {
  @summary() {
    println "A doc block carries no TODO or FIXME marker; pending work belongs in the tracker."
  }

  @languages() {
    @arr shell
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Open an issue for the outstanding work and take the paragraph out of the" \
      "doc."
  }

  @run() {
    lint__comments__comment_lint_no_doc_block_tracker "$@"
  }
}

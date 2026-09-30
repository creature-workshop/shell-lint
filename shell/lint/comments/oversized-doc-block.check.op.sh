#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/comments/api.sh"

:<<'DOC'
The oversized-doc-block check: one lint check plugin. See
shell/lint/registry.sh for what the roles mean.
DOC
@check.oversized-doc-block() {
  @summary() {
    println "A doc block's prose stays within the cap for its kind; labelled reference sections are not counted."
  }

  @languages() {
    @arr shell
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "State the contract and stop; the mechanics are in the code underneath." \
      "Reference material stays free: put it under a labelled section (Usage," \
      "Flags, Parameters, Returns, Environment, ...) and it is not counted."
  }

  @run() {
    lint__comments__comment_lint_no_oversized_doc_block "$@"
  }
}

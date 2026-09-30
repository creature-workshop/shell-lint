#!/usr/bin/env bash

import "$SHELL_LINT_DIR/shell/lint/api.sh"

:<<'DOC'
The awk-style check: one lint check plugin. See shell/lint/registry.sh for
what the roles mean.
DOC
@check.awk-style() {
  @summary() {
    println "awk control-flow bodies are braced, function locals are unpassed __ parameters, and the rules close the file below every function."
  }

  @languages() {
    @arr awk
  }

  @scopes() {
    @arr code
  }

  @hint() {
    printf '%s\n' \
      "Brace every if, else, for and while body, and declare a function's locals" \
      "as trailing parameters no caller passes, prefixed __. Pattern-action rules" \
      "are already braced; fence and container state stays global. Put every" \
      "function above the first rule: the BEGIN, END and pattern-action rules" \
      "close the file, so a reader meets the helpers before the entry."
  }

  @run() {
    lint__awk_style "$@"
  }
}

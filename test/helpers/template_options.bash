#!/usr/bin/env bash

: <<'DOC'
The options the template checks' suites hand their run functions: the
catalog's facts as the fixtures beside shell/lint/checks/templates write them.
Load after helpers/setup.bash.
DOC

# Options whose templates block names the fixtures beside the module as the
# catalog: the pattern, the base, and the mark as the fixtures write it.
catalog_options() {
  __templates="$(@obj \
    '.glob' 'shell/lint/checks/templates/*.fixture.yml' \
    '.base' 'shell/lint/checks/templates/base.fixture.yml' \
    '.mark' 'scheduler\/next-merge'
  )"
  @obj '.config' "$(@obj '.templates' "$__templates")"
}

# Options whose pattern names every file, for a fixture written under the
# test's tmpdir, with the mark set.
any_file_options() {
  @obj '.config' "$(@obj '.templates' "$(@obj '.glob' '*' '.mark' 'scheduler\/next-merge')")"
}

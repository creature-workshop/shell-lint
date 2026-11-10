#!/usr/bin/env bash

: <<'DOC'
The options the template checks' suites hand their run functions: the
catalog's facts as the fixtures beside shell/lint/checks/templates write them.
Load after helpers/setup.bash.
DOC

# Options whose templates block names the fixtures beside the module as the
# catalog: the pattern, the base, and the mark as the fixtures write it.
catalog_options() {
  @obj __templates \
    '.glob' 'shell/lint/checks/templates/*.fixture.yml' \
    '.base' 'shell/lint/checks/templates/base.fixture.yml' \
    '.mark' 'scheduler\/next-merge'
  @obj __catalog_options__obj_1 '.templates' "$__templates"
  @obj __catalog_options__out '.config' "$__catalog_options__obj_1"
  println "$__catalog_options__out"
}

# Options whose pattern names every file, for a fixture written under the
# test's tmpdir, with the mark set.
any_file_options() {
  @obj __any_file_options__obj_2 '.glob' '*' '.mark' 'scheduler\/next-merge'
  @obj __any_file_options__obj_3 '.templates' "$__any_file_options__obj_2"
  @obj __any_file_options__out '.config' "$__any_file_options__obj_3"
  println "$__any_file_options__out"
}

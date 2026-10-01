#!/usr/bin/env bats
# Covers what the template checks share, shell/lint/checks/templates/api.sh: the
# facts read from lint.json's templates block.

setup() {
  load helpers/setup.bash
  load helpers/lint_fixtures.bash
  load helpers/template_options.bash
  source "$SHELL_LINT_DIR/shell/lint/checks/templates/api.sh"
  export PROJ="$SHELL_LINT_DIR"
}

@test "lint__checks__templates__glob: templates/*/template.yml when lint.json names no pattern" {
  run lint__checks__templates__glob "$(@obj)"
  assert_output "templates/*/template.yml"
}

@test "lint__checks__templates__every_push: empty when lint.json names none" {
  run lint__checks__templates__every_push "$(@obj)"
  assert_output "$(@arr)"
}

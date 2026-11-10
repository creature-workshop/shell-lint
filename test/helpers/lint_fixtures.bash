#!/usr/bin/env bash

: <<'DOC'
Fixture plumbing for the lint suites: a source file the checks will read, a
copy of it outside every test tree, and a staged-over-baseline git repository
for the --added-only mode. Load after helpers/setup.bash.
DOC

# Writes stdin to <name> under the test tmpdir and prints its path, so each
# case gets a file the linters treat as a source of the named kind.
fixture() {
  __fixture__path="$BATS_TEST_TMPDIR/${1}"
  mkdir -p "$(dirname "$__fixture__path")"
  cat > "$__fixture__path"
  printf '%s' "$__fixture__path"
}

# Like fixture, but outside any directory named "test": BATS_TEST_TMPDIR sits
# at <run tmpdir>/test/<n>, and cli/lint skips test paths, so a fixture written
# there would be silently dropped and the assertion would pass vacuously. The
# copy lives under a directory named for the suite, one per test.
cli_fixture() {
  __cli_fixture__suite="$(basename "$BATS_TEST_FILENAME" .bats)"
  __cli_fixture__path="$BATS_RUN_TMPDIR/$__cli_fixture__suite-cli/$BATS_TEST_NUMBER/${1}"
  mkdir -p "$(dirname "$__cli_fixture__path")"
  cat > "$__cli_fixture__path"
  printf '%s' "$__cli_fixture__path"
}

: <<'DOC'
Stands up a git repository at <repo> whose one commit holds <file> with
<baseline> content, then stages <staged> content over it, so a scanner reading
the index sees exactly the lines the staged diff added. Sets STAGED_FILE to
<file>. The caller points PROJ at <repo> when the scanner reads it from there.

Call this as a plain command, never inside $(...): STAGED_FILE has to land in
the caller's shell.

Usage: stage_over_baseline <repo> <file> <baseline> <staged>
DOC
stage_over_baseline() {
  # shellcheck disable=SC2034  # read by the suite that loaded this helper
  STAGED_FILE="$2"

  mkdir -p "$1/$(dirname "$2")"
  git -C "$1" init --quiet
  git -C "$1" config user.email lint@example.com
  git -C "$1" config user.name Lint

  printf '%s\n' "$3" > "$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit --quiet -m baseline

  printf '%s\n' "$4" > "$1/$2"
  git -C "$1" add "$2"
}

: <<'DOC'
Stands up a git repository at <repo> with two commits. The first holds
every file already under <repo>, and <file> with <baseline> content. The
second holds <file> with <head> content. A scanner that reads the commits
since the first therefore sees exactly the lines the second added. Sets
COMMITTED_FILE to <file> and BASE_COMMIT to the first commit. The caller
points PROJ at <repo> when the scanner reads it from there.

Call this as a plain command, never inside $(...): the two variables have
to land in the caller's shell.

Usage: commit_over_baseline <repo> <file> <baseline> <head>
DOC
commit_over_baseline() {
  # shellcheck disable=SC2034  # read by the suite that loaded this helper
  COMMITTED_FILE="$2"

  mkdir -p "$1/$(dirname "$2")"
  git -C "$1" init --quiet
  git -C "$1" config user.email lint@example.com
  git -C "$1" config user.name Lint

  printf '%s\n' "$3" > "$1/$2"
  git -C "$1" add -A
  git -C "$1" commit --quiet -m baseline
  # shellcheck disable=SC2034  # read by the suite that loaded this helper
  BASE_COMMIT="$(git -C "$1" rev-parse HEAD)"

  printf '%s\n' "$4" > "$1/$2"
  git -C "$1" add -A
  git -C "$1" commit --quiet -m head
}

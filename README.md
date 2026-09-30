# shell-lint

The house-style lint for shell, awk, jq, markdown and yaml sources: the
check registry, the discovery of what a run reads, the runner, and every
check. It is a shellops consumer: `shell/lint` holds the engine and the
checks, and `cli/lint` runs them over a repository.

    SHELLOPS_DIR=<shellops> SHELL_SCAN_DIR=<shell-scan> \
      PROJ=<the repository> cli/lint [--list] [--check <name>]... [--added-only] [files...]

`cli/lint --help` says what a run does and what `lint.json` may set. Each
variable is the root of that repository's copy; one left unset falls back
to the copy vendored under `shell/`. The checks come from three places, in
this order, and a name keeps its first plugin: `shell/lint` here, shellops'
`lib`, whose modules ship the checks that police them, and the directories
the repository's `lint.json` lists under `checks`.

A check is a plugin file, `<name>.check.op.sh`, and `shell/lint/registry.sh`
says what it defines. A detector reads a file through the scanner of
[shell-scan](../shell-scan), so every reader of a shell file draws the same
boundaries; what the comment checks share about a doc block is
`shell/lint/comments/doc_block.awk`.

The tests under `test/` cover each check and the CLI. `shell/.ops` and
`shell/.scan` vendor shellops and shell-scan for this repository's own
tests and lint, and for nothing else. A repository takes this lint at a
pin.

The work is tracked in Linear on the SILT project, from STRATA-231.

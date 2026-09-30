# ADR.1: A repository takes shell-lint at a pin, and a run's checks come from three roots

- Status: approved
- Date: 2026-09-30
- Merge request: https://gitlab.creature-workshop.com/ksoft/shell-lint/-/merge_requests/1
- Argued from: https://linear.app/grand-cluster-city/issue/STRATA-221
- Implementation: STRATA-231

## Context

shellops' `ops lint` ran the house-style checks over every repository
under ksoft from shellops' own `lib/lint`, so a check, a detector or a fix
to the engine waited on shellops' pipeline, and the engine grew with every
new rule. Jerrod ruled on 2026-09-30 that the lint is extracted: it keeps
growing and needs performance work of its own. The scanner it reads files
through is
[ADR.1@shell-scan](https://gitlab.creature-workshop.com/ksoft/shell-scan/-/blob/main/docs/decisions/000001-a-repository-adopts-shell-scan-at-a-pin-and-composes-its-own-program.md),
and each is taken at a pin.

## Decision

- shell-lint is a shellops consumer. `shell/lint` holds the registry,
  discovery, the runner and every check; `cli/lint` runs them. At run time
  it takes shellops, for structs, args, git, the language table and the
  interpreter that lowers a check plugin, and it takes shell-scan for the
  scanner its detectors load.
- A repository takes shell-lint at a pin, and runs `cli/lint` with `PROJ`
  at its own root. How its copies are made present, and where, is decided
  by the dependency work under way and not here. Whether it is a run-time or a dev-time dependency, in the sense
  [ADR.33@strata](https://gitlab.creature-workshop.com/ksoft/strata/-/blob/main/adrs/000033-dependencies/adr.md)
  gives the words, is the adopter's to say, from how its own code uses the
  copy; nothing here decides it.
- A run's checks come from three roots, in this order, and a name keeps its
  first plugin: `shell/lint` here; shellops' `lib`, because a shellops
  module ships the check that polices it; and the directories the adopter's
  `lint.json` lists under `checks`. A check is a plugin file,
  `<name>.check.op.sh`, wherever it sits.
- The structs checks stay in shellops, with the module they police. Until
  shellops takes shell-lint at a pin and its own `lib/lint` leaves, both
  copies exist and the first root shadows the second by name.

## Consequences

- shellops adopts shell-lint in step 2 of STRATA-221, when its `lib/lint`
  and `cli/lint` leave and its `lint.json` names `lib/structs/lint` under
  `checks`. strata and the catalog's `shell--ops-lint` member follow with a
  pin.
- A check lands here, with its tests, in a pipeline that runs the lint's
  own suites and nothing else; an adopter sees it when it moves its pin.
- The performance work Jerrod named is scoped on its own ticket and done
  here, where a change to the engine no longer waits on shellops.
- The cycle at dev time, shellops checking itself with a lint that runs on
  shellops, is held open by the pins, as strata's dependency record holds
  strata's.

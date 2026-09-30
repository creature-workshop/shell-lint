# The kinds of change a label names

A merge request carries one label from this table, and the label decides how
the release chain treats the change: which counter it moves, whether the
changelog lists it, and whether a consumer has to read anything before taking
the version. The table exists because the names alone do not say that: a
reader who meets `crit/breaking` on a merge request needs to know it moves the
major counter and that a note to consumers is owed, and the label's colour
says neither. The rows are the closed list; a label that is not here is not a
kind of change, and the chain refuses it. A reader deciding which label a
change takes reads the second column and picks the first row that holds.

## Glossary

- **label**: the label's name, as the merge request carries it.
- **counter**: the counter of the version the change moves.
- **One row** is one kind of change.

| label | counter |
|---|---|
| crit/breaking | major |

And the counters again, in a table of their own:

| counter | moves |
|---|---|
| major | the first number |

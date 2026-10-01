# ADR.7: A change is labelled with one kind

- Status: approved
- Date: 2026-01-01
- Merge request: https://example.com/org/tool/-/merge_requests/4
- Implementation: not started

## Context

A merge request needs one label that says what kind of change it carries.

## Decision

Every merge request carries one of these labels:

```
| label | counter |
|---|---|
| crit/breaking | major |
| type/feature | minor |
```

## Consequences

A change with no label is refused.

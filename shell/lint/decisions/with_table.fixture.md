# ADR.7: A change is labelled with one kind

- Status: approved
- Date: 2026-01-01
- Merge request: https://example.com/org/tool/-/merge_requests/4
- Implementation: not started

## Context

A merge request needs one label that says what kind of change it carries.

## Decision

Every merge request carries one of the labels in
[Table 1: The kinds of change a label names](tables/kinds.md), and the
release chain reads the counter from it.

## Consequences

A change with no label is refused.

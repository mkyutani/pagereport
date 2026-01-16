---
name: pagereport-subagents
description: Guidelines and entrypoints for the 11 pagereport subagents.
---

# Pagereport Subagents

## Scope
Stateless subagents: JSON in/out, no user confirmation.

## Conventions
- Output JSON only (success or error)
- Use error levels: CRITICAL, MAJOR, MINOR
- Return immediately after emitting JSON

## References
- `references/subagent-conventions.md`
- `references/agents/<name>.md`

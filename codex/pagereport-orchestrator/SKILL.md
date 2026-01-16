---
name: pagereport-orchestrator
description: Run the 11-step pagereport workflow by orchestrating subagents and passing JSON between steps.
---

# Pagereport Orchestrator

## Purpose
Run the 11-step workflow, passing JSON between steps and running steps 7-9 in parallel per material.

## Inputs
- Meeting page URL (HTML or PDF)
- Agency id: cas, cao, meti, chusho, mhlw, fsa, digital

## References
- `references/base_workflow.md`
- `references/subagent-conventions.md`
- `../pagereport-subagents/references/agents/*.md`

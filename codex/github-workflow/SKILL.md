---
name: github-workflow
description: Commit and pull request conventions for this repository.
---

# GitHub Workflow

## Branches
- feature/<desc>
- fix/<desc>
- docs/<desc>
- refactor/<desc>
- Never commit directly to main.

## Commit messages
Use Conventional Commits:
```
<type>: <subject>
```
Rules:
- Use imperative mood
- Under 72 chars
- No trailing period
- Types: feat, fix, docs, refactor, test, chore, perf

## Pull requests
Include: what/why, related issues, tests run, breaking changes.

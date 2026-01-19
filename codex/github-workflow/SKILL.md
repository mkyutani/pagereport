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
Format: `{prefix}: {message}` or `{prefix}: {message} (#{issue_number})`

Prefixes:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `refactor` - Code refactoring
- `chore` - Maintenance tasks
- `test` - Adding or modifying tests

Constraints:
- Language: English
- Max 20 words
- Imperative style
- Single sentence (one line only)
- **No author footers** - Do not add "Generated with Claude Code" or "Co-Authored-By" footers

## Pull requests
Include: what/why, related issues, tests run, breaking changes.

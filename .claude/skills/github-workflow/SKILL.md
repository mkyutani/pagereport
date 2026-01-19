---
name: github-workflow
description: GitHub workflow rules for commits and pull requests
auto-execute: false
---

# GitHub Workflow Rules

This skill defines the GitHub workflow rules for commits and pull requests in this repository.

## Branch Strategy

**Main Branch Protection**:
- `main` branch contains stable, tested code
- Never commit directly to `main`
- All changes go through feature branches and pull requests

**Branch Naming Convention**:
```
feature/<description>  # New features (e.g., feature/pdf-caching)
fix/<description>      # Bug fixes (e.g., fix/date-parsing-error)
docs/<description>     # Documentation updates (e.g., docs/update-readme)
refactor/<description> # Code refactoring (e.g., refactor/pdf-scoring)
```

**Branch Lifecycle**:
1. Create branch from latest `main`: `git checkout -b feature/my-feature`
2. Make commits following commit message rules
3. Create pull request when ready
4. Merge to `main` after self-review
5. Delete feature branch after merge

## Commit Message Rules

Format: `{prefix}: {message}` or `{prefix}: {message} (#{issue_number})`

**Prefixes**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `refactor` - Code refactoring
- `chore` - Maintenance tasks
- `test` - Adding or modifying tests

**Constraints**:
- Language: English
- Max 20 words
- Imperative style ("add" not "added" or "adds")
- Single sentence (one line only)
- **No author footers** - Do not add "Generated with Claude Code" or "Co-Authored-By" footers

**Examples**:
```bash
feat: add PDF download caching to improve performance
fix: correct Reiwa era date conversion in metadata extraction
docs: update commit message rules in github-workflow skill
refactor: flatten scripts directory structure
```

## Pull Request Guidelines

Even for individual development, PRs provide valuable benefits:
- Self-review opportunity before merging
- Clear history of what changed and why
- Documentation for future reference

**PR Creation Checklist**:
1. **Title**: Use same format as commit messages (type: description)
2. **Description**: Include:
   - What changed and why
   - Related issue numbers (if applicable)
   - Testing performed
   - Any breaking changes or migration notes
3. **Self-Review**: Review all changed files before merging
4. **Status Check**: Ensure all tests pass (if CI is configured)

**Merge Strategy**:
- **Squash and merge**: Recommended for feature branches with many small commits
- **Merge commit**: For significant features where commit history is valuable
- **Rebase and merge**: For clean linear history (requires force-push awareness)

## Claude Code Integration

When working with Claude Code:
- Claude will follow these rules when creating commits or PRs
- When asked to commit changes, Claude will generate properly formatted commit messages
- Claude will NOT add "Generated with Claude Code" or "Co-Authored-By" footers
- Review Claude's proposed changes before approving commits/PRs

## Bash Tool Usage Restrictions

**IMPORTANT: Bash tool should ONLY be used for shell script execution:**
- File reading: Bash cat/head/tail **PROHIBITED** → Use **Read tool** instead
- File searching: Bash find/ls **PROHIBITED** → Use **Glob tool** instead
- Content searching: Bash grep/rg **PROHIBITED** → Use **Grep tool** instead
- File editing: Bash sed/awk **PROHIBITED** → Use **Edit tool** instead
- File writing: Bash echo/cat **PROHIBITED** → Use **Write tool** instead
- User communication: Bash echo **PROHIBITED** → Use direct text output instead
- Allowed usage: Shell scripts in `.claude/skills/common/scripts/`, git commands, docker, and other system commands

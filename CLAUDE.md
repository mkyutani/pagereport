# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code skills project for generating structured summaries of Japanese government meeting pages. The main skill (`pagereport`) processes both HTML pages and PDF documents from government websites (primarily www.cas.go.jp), extracting metadata, analyzing meeting materials, and producing two types of output files:

1. **Summary file** (`*_summary.txt`): 1,000-character abstract + material list + links
2. **Detail file** (`*_detail.md`): Comprehensive report up to 10,000 characters for future reference

## Architecture

### Core Components

**Skill Definition**: `.claude/commands/pagereport.md`
- Contains the complete workflow specification for processing government meeting pages
- Defines a 9-step processing pipeline from content fetching to file output
- Includes detailed rules for PDF prioritization, document type detection, and token optimization

**Permissions**: `.claude/settings.local.json`
- Pre-authorized tools: `WebFetch(domain:www.cas.go.jp)`, `Bash(curl:*)`, `Bash(mkdir:*)`, `Bash(ls:*)`
- These permissions allow the skill to operate without manual approval for common operations

### Processing Pipeline

The skill follows a structured 9-step workflow:

1. **Content Acquisition**: Fetch HTML with WebFetch or read local/remote PDFs
2. **Metadata Extraction**: Auto-extract meeting name, date (converted to YYYYMMDD), round number, location
3. **Document Type Detection**: Score PDFs (1-5 scale) across 7 categories (Word, PowerPoint, Agenda, Roster, News, Survey, Other)
4. **Meeting Overview Creation**: Extract from HTML or agenda PDF
5. **Minutes Reference**: Locate actual participant statements if available
6. **Selective Material Reading**: Score PDFs (1-5) by relevance, download top-priority files with curl to `/tmp/`
7. **Type-Specific Reading**: Apply token-optimized strategies based on document type and page count
8. **Summary Generation**: Create structured abstract (1,000 chars, 5-element structure) + detailed report
9. **File Output**: Write to `{meeting_name}/{meeting_name}_{date}_{round}_summary.txt` and `*_detail.md`

### Key Design Principles

**Token Optimization**:
- Dynamic reading strategies based on page count (≤5: full text, ≤20: ToC + key sections, ≤50: ToC + summary + conclusion, >50: metadata + ToC + summary only)
- Use Read tool's limit/offset parameters for large documents
- Extract only essential content (titles, section headers) before detailed reading
- Skip low-priority materials (rosters, seating charts, reference materials)

**PDF Prioritization System**:
- Scoring criteria: relevance to summary, importance, document type, chronological position
- Filename pattern recognition (e.g., `shiryou1.pdf` > `sankou*.pdf`)
- Cross-reference with meeting minutes for mention frequency
- Adjustment rules: prevent agenda from getting max score (5) when substantial materials exist; cap reference materials at score 4

**Document Type Detection**:
- Read first 1-10 pages to determine type
- PowerPoint vs Word distinction: look for bullet points, slide titles, nominal phrases
- Enables type-specific processing strategies

**Abstract Structure** (論文形式):
1. Background/Context (2-3 sentences) - **Must include meeting name and round number**
2. Purpose (1-2 sentences)
3. Discussion Content (3-5 sentences)
4. Decisions/Agreements (3-5 sentences)
5. Future Direction (2-3 sentences)
- Single paragraph, 1,000 characters max, factual only (no speculation)
- **URL must be included on a new line immediately after the abstract paragraph**

## Common Operations

### Running the Skill

```bash
# Invoke with URL (HTML page or PDF)
/pagereport "https://www.cas.go.jp/jp/seisaku/nipponseichosenryaku/kaigi/dai2/gijisidai.html"
```

The skill automatically:
- Extracts meeting name from HTML title/h1 or PDF metadata
- Converts dates from Japanese calendar (令和X年Y月Z日) to YYYYMMDD format
- Detects round number (第X回)
- Creates `./output` directory if it doesn't exist
- Downloads priority PDFs to `/tmp/` using curl
- Generates both summary and detail files in `./output/`

### Manual Testing Commands

```bash
# Test PDF download
curl -o /tmp/test.pdf "https://example.com/document.pdf"

# Check output directory
ls -la output/

# Verify file creation
cat "output/{meeting_name}_{date}_{round}_summary.txt"
```

## Important Implementation Notes

### Error Handling

1. **HTML fetch failure**: Retry with normalization, log each stage
2. **PDF download failure**: Log curl error, skip file, note "download failed" in detail.md
3. **PDF read failure**: Log Read tool error, mark as "unreadable" in output
4. **Missing metadata**: Prompt user for meeting name, date, or round number

### Content Cleaning (HTML)

**Remove**: Headers, footers, sidebars, breadcrumbs, navigation, ads, auxiliary content
**Preserve**: Meeting minutes, reports, agendas, decisions, essential content (headings, lists, tables, links)

### PDF Processing Rules

- **Remote PDFs**: Download with curl to `/tmp/` first, then read with Read tool
- **Local PDFs**: Read directly with Read tool
- **Empty content detection**: Skip if only cover page, images without captions, or data tables without context
- **Parallel downloads**: Avoid; use sequential downloads to prevent rate limiting

### Quality Requirements

- **No speculation**: Only use information actually present in documents
- **No metadata**: Exclude file sizes, software requirements, timestamps
- **Verification**: Check for actual participant quotes in meeting minutes (「○○大臣」「○○委員」)
- **Absolute URLs**: Convert all relative PDF links to absolute URLs in output

## File Organization

```
output/
├── {meeting_name}_{YYYYMMDD}_第{N}回_summary.txt
└── {meeting_name}_{YYYYMMDD}_第{N}回_detail.md
```

Example:
```
output/
├── 日本成長戦略会議_20251224_第2回_summary.txt
└── 日本成長戦略会議_20251224_第2回_detail.md
```

## Modification Guidelines

When editing the skill definition (`.claude/commands/pagereport.md`):

- Maintain the 9-step structure for clarity
- Update token optimization strategies if processing different document types
- Adjust PDF scoring criteria based on observed relevance patterns
- Keep abstract structure strict (5 elements, 1 paragraph, 1,000 chars)
- Test with actual government meeting pages to validate changes
- Ensure all PDF URLs are converted to absolute paths

## GitHub Workflow Rules

### Branch Strategy

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

### Commit Message Rules

Follow **Conventional Commits** format for clear history and potential automation:

```
<type>: <subject>

[optional body]
```

**Format Requirements**:
- Subject line: Use imperative mood ("add" not "added" or "adds")
- Subject line: No period at the end
- Subject line: Keep under 72 characters
- Write in English
- Body text is optional but allowed for detailed explanations

**DO NOT Include**:
- "Generated with Claude Code" footer
- "Co-Authored-By: Claude" footer
- Emoji or decorative elements

**Types**:
- `feat`: New feature (e.g., `feat: add PDF caching mechanism`)
- `fix`: Bug fix (e.g., `fix: correct date parsing for Reiwa era dates`)
- `docs`: Documentation only (e.g., `docs: update CLAUDE.md with workflow rules`)
- `refactor`: Code refactoring without behavior change (e.g., `refactor: extract PDF scoring logic`)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (e.g., `chore: update dependencies`)
- `perf`: Performance improvements

**Examples**:
```bash
feat: add PDF download caching to improve performance

fix: correct Reiwa era date conversion in metadata extraction

docs: add GitHub workflow section to CLAUDE.md

refactor: extract document type detection into separate function
```

### Pull Request Guidelines

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

**PR Template** (optional, create `.github/pull_request_template.md`):
```markdown
## Changes

<!-- What was changed -->

## Motivation

<!-- Why this change is needed -->

## Testing

<!-- How this was tested -->
- [ ] Manual testing completed
- [ ] Impact on existing features verified

## Notes

<!-- Any additional notes or considerations -->
```

**Merge Strategy**:
- **Squash and merge**: Recommended for feature branches with many small commits
- **Merge commit**: For significant features where commit history is valuable
- **Rebase and merge**: For clean linear history (requires force-push awareness)

### Claude Code Integration

When working with Claude Code:
- Claude will follow these rules when creating commits or PRs
- When asked to commit changes, Claude will generate properly formatted commit messages
- Claude will NOT add "Generated with Claude Code" or "Co-Authored-By" footers
- Review Claude's proposed changes before approving commits/PRs

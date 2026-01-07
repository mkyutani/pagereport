# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code skills project for generating structured summaries of Japanese government meeting pages. The main skill (`pagereport`) processes both HTML pages and PDF documents from government websites (primarily www.cas.go.jp), extracting metadata, analyzing meeting materials, and producing a unified report file:

**Report file** (`*_report.md`): Markdown report containing a 1,000-character abstract (enclosed in code fences for easy extraction) + material list + comprehensive details up to 10,000 characters for future reference

## Architecture

### Core Components

**Skill Definitions**: `.claude/skills/`
- `pagereport-cas/`: Internal Cabinet Office (内閣府) meeting pages
- `pagereport-cao/`: Cabinet Office (総務省) meeting pages
- `pagereport-meti/`: Ministry of Economy, Trade and Industry (経済産業省) meeting pages
- `common/base_workflow.md`: Shared workflow specification used by all skills
  - Defines an 11-step processing pipeline from content fetching to Bluesky posting
  - Includes detailed rules for PDF prioritization, document type detection, and token optimization
- `document-type-classifier/`: Subagent for Step 6 (document type detection)
  - Analyzes PDF structure to determine document type (Word/PowerPoint/etc)
  - Supports parallel execution for multiple PDFs
- `material-analyzer/`: Subagent for Step 8 (material analysis)
  - Applies document type-specific reading strategies
  - Supports parallel execution for multiple materials
  - Generates detailed summaries with key points

**Commands**: `.claude/commands/`
- `bluesky-post.md`: Standalone command to extract abstract from report and post to Bluesky
  - Can be invoked manually: `/bluesky-post <report_file_path>`
  - Automatically called by skills in Step 11

**Permissions**: `.claude/settings.local.json`
- Pre-authorized tools: `Bash(curl:*)`, `Bash(mkdir:*)`, `Bash(ls:*)`, `Bash(python3:*)`, `WebFetch(domain:github.com)`, `Read(path:/tmp/*)`, `Write(path:/tmp/*)`, `Edit(path:/tmp/*)`
- These permissions allow the skill to operate without manual approval for common operations

### Processing Pipeline

The skill follows a structured 11-step workflow:

1. **Content Acquisition**: Fetch HTML with WebFetch or read local/remote PDFs
2. **Metadata Extraction**: Auto-extract meeting name, date (converted to YYYYMMDD), round number, location
3. **Meeting Overview Creation**: Extract from HTML or agenda PDF
4. **Minutes Reference**: Locate actual participant statements if available
5. **Material Selection and Download**: Score PDFs (1-5) by relevance, download top-priority files with curl to `/tmp/`
6. **Document Type Detection** (**Parallel Subagents**): Use `document-type-classifier` subagent to judge PDF type (Word/PowerPoint/Other) from first 5 pages. Multiple PDFs are classified in parallel for speed.
7. **PDF to Markdown Conversion**: Convert with docling (PowerPoint) or pdftotext (Word) for token optimization
8. **Type-Specific Reading** (**Parallel Subagents**): Use `material-analyzer` subagent to apply token-optimized strategies based on document type and page count. Multiple materials are analyzed in parallel, reducing processing time by 30-50%.
9. **Summary Generation**: Create structured abstract (1,000 chars, 5-element structure) + detailed report
10. **File Output**: Write to `{meeting_name}_{round}_{date}_report.md` with abstract enclosed in code fences
11. **Bluesky Posting**: Automatically post the abstract to Bluesky using `ssky post` command

### Key Design Principles

**Parallel Processing**:
- Document type detection (Step 6) runs in parallel for multiple PDFs
- Material analysis (Step 8) runs in parallel for multiple materials
- Reduces overall processing time by 30-50% when handling 3+ materials
- Each subagent operates independently with its own context

**Token Optimization**:
- Convert PDFs to Markdown with docling container when beneficial (>50 pages, complex layouts)
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
/pagereport-cas "https://www.cas.go.jp/jp/seisaku/nipponseichosenryaku/kaigi/dai2/gijisidai.html"
/pagereport-cao "https://www.cao.go.jp/..."
/pagereport-meti "https://www.meti.go.jp/..."
```

The skill automatically:
- Extracts meeting name from HTML title/h1 or PDF metadata
- Converts dates from Japanese calendar (令和X年Y月Z日) to YYYYMMDD format
- Detects round number (第X回)
- Creates `./output` directory if it doesn't exist
- Downloads priority PDFs to `/tmp/` using curl
- Generates unified report file in `./output/`
- Posts the abstract to Bluesky using `ssky post` (if logged in)

### Posting to Bluesky Manually

If you want to post an existing report to Bluesky:

```bash
# Use the bluesky-post command
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

This is useful when:
- You skipped Bluesky posting during initial generation (not logged in)
- You want to re-post a report
- You generated a report before Bluesky integration was added

### Manual Testing Commands

```bash
# Test PDF download
curl -o /tmp/test.pdf "https://example.com/document.pdf"

# Check output directory
ls -la output/

# Verify file creation
cat "output/{meeting_name}_{round}_{date}_report.md"

# Test Bluesky login status
ssky profile

# Test abstract extraction
awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "output/{meeting_name}_{round}_{date}_report.md"

# Test Bluesky posting (dry run)
awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "output/{meeting_name}_{round}_{date}_report.md" | ssky post -d
```

## Important Implementation Notes

### Error Handling

1. **HTML fetch failure**: Retry with normalization, log each stage
2. **PDF download failure**: Log curl error, skip file, note "download failed" in detail.md
3. **PDF read failure**: Log Read tool error, mark as "unreadable" in output
4. **Missing metadata**: Prompt user for meeting name, date, or round number
5. **Bluesky posting failure**: Log warning, skip posting, report generation continues normally

### Content Cleaning (HTML)

**Remove**: Headers, footers, sidebars, breadcrumbs, navigation, ads, auxiliary content
**Preserve**: Meeting minutes, reports, agendas, decisions, essential content (headings, lists, tables, links)

### PDF Processing Rules

**PDF Acquisition:**
- **Remote PDFs**: Download with curl to `/tmp/` first (sequential downloads only)
- **Local PDFs**: Read directly with Read tool

**Document Type-Based PDF Processing (Token Optimization):**

Process PDFs differently based on document type (determined in Step 3: Document Type Detection):

**Strategy Overview:**
- **PowerPoint-origin PDFs** → Use docling (structure preservation critical)
- **Word-origin PDFs** → Use pdftotext (fast linear text extraction)
- **Other PDFs** → Use pdftotext or Read tool based on size

### Method 1: pdftotext for Word-origin PDFs (Fast)

Word-origin PDFs have linear text structure, so pdftotext provides fast, efficient extraction:

```bash
# Check if pdftotext is available
which pdftotext  # Should output: /usr/bin/pdftotext

# Extract text from PDF
pdftotext /tmp/document.pdf /tmp/document.txt

# Check the output
wc -l /tmp/document.txt  # Count lines

# Read with Read tool
# The text file can then be processed in Step 7
```

**Advantages:**
- Very fast (seconds vs minutes for docling)
- No Docker dependency
- Clean text output
- Works well for linear documents (Word-origin PDFs, reports, papers)

**Limitations:**
- No layout preservation (but Word PDFs are linear anyway)
- Headers/footers may be included (can be filtered)
- No structure detection (headings must be identified by content analysis)

### Method 2: docling for PowerPoint-origin PDFs (Structure Preservation)

PowerPoint PDFs require structure preservation (slides, bullets, layout), so use docling:

```bash
# Start docling-serve container (one-time setup)
docker run -d -p 5001:5001 --name docling-server quay.io/docling-project/docling-serve
```

**Synchronous Conversion (Small PDFs only):**

**IMPORTANT**: Synchronous processing has a 120-second timeout limit (DOCLING_SERVE_MAX_SYNC_WAIT). Only use for small PDFs (<10 pages estimated). For medium to large PDFs, use asynchronous processing.

```bash
# Convert PDF to Markdown (synchronous - times out for large PDFs)
curl -s -X POST http://localhost:5001/v1/convert/file \
  -F "files=@/tmp/document.pdf" \
  > /tmp/document_result.json

# Extract Markdown from JSON response (synchronous response structure)
cat /tmp/document_result.json | \
  python3 -c "import json, sys; print(json.load(sys.stdin)['md_content'])" \
  > /tmp/document.md
```

**Asynchronous Conversion (Recommended for >10 pages):**

For medium to large PDFs, use asynchronous processing to avoid timeout:

```bash
# 1. Submit conversion task
TASK_ID=$(curl -s -X POST http://localhost:5001/v1/convert/file/async \
  -F "files=@/tmp/document.pdf" | \
  python3 -c "import json, sys; print(json.load(sys.stdin)['task_id'])")

# 2. Poll for completion (check every 10-30 seconds)
while true; do
  STATUS=$(curl -s "http://localhost:5001/v1/status/poll/$TASK_ID" | \
    python3 -c "import json, sys; print(json.load(sys.stdin)['task_status'])")
  echo "Status: $STATUS"
  if [ "$STATUS" = "success" ]; then
    break
  fi
  sleep 15
done

# 3. Retrieve result (asynchronous response structure)
curl -s "http://localhost:5001/v1/result/$TASK_ID" | \
  python3 -c "import json, sys; print(json.load(sys.stdin)['document']['md_content'])" \
  > /tmp/document.md
```

**Processing Multiple PDFs Efficiently:**

Submit multiple conversions in parallel for efficiency:

```bash
# Submit all PDFs asynchronously
TASK_ID_1=$(curl -s -X POST http://localhost:5001/v1/convert/file/async -F "files=@/tmp/doc1.pdf" | python3 -c "import json, sys; print(json.load(sys.stdin)['task_id'])")
TASK_ID_2=$(curl -s -X POST http://localhost:5001/v1/convert/file/async -F "files=@/tmp/doc2.pdf" | python3 -c "import json, sys; print(json.load(sys.stdin)['task_id'])")
TASK_ID_3=$(curl -s -X POST http://localhost:5001/v1/convert/file/async -F "files=@/tmp/doc3.pdf" | python3 -c "import json, sys; print(json.load(sys.stdin)['task_id'])")

# Poll and retrieve results for each task
# (Repeat polling pattern above for each TASK_ID)
```

**After Conversion:**

```bash
# Read the Markdown with Read tool
# If Markdown file is too large (>256KB due to embedded images), use Grep to extract structure:
grep "^#{1,3}\s+" /tmp/document.md  # Extract headings to understand structure
```

**Usage Decision Criteria (Document Type Based):**

*PowerPoint-origin PDFs → Use docling:*
- Slide structure preservation is critical (bullet points, slide titles, layout)
- Use asynchronous processing for medium to large files (>10 pages)
- Use synchronous processing only for small files (<10 pages)
- Note: If synchronous times out, automatically retry with asynchronous
- Complex tables/layouts benefit from structured Markdown
- Scanned PDFs requiring OCR

*Word-origin PDFs → Use pdftotext:*
- Linear text structure allows fast, simple extraction
- No need for layout preservation (sequential reading is sufficient)
- Much faster than docling (seconds vs minutes)
- Outputs plain text, which can be processed with simple tools
- **Command**: `pdftotext /tmp/document.pdf /tmp/document.txt`

*Other PDFs (Agendas, Rosters, Surveys) → Size-based decision:*
- Small (<20 pages): Read tool directly
- Medium (20-50 pages): pdftotext preferred
- Large (>50 pages): pdftotext + partial reading with offset/limit

*Fallback to Read tool directly when:*
- pdftotext not available in environment
- Docker unavailable (for docling)
- Conversion fails entirely
- Very small PDFs (≤5 pages) where conversion overhead isn't worth it

**Processing Time Guidelines:**

*PowerPoint PDFs (docling):*
- Small PDFs (<10 pages): 1-2 minutes (synchronous or asynchronous)
- Medium PDFs (10-30 pages): 3-5 minutes (asynchronous recommended)
- Large PDFs (30-50 pages): 5-8 minutes (asynchronous required)
- Multiple PDFs in parallel: Time of longest PDF + 1-2 minutes overhead

*Word PDFs (pdftotext):*
- Small PDFs (<10 pages): 5-10 seconds
- Medium PDFs (10-30 pages): 10-30 seconds
- Large PDFs (30-50 pages): 30-60 seconds
- Very large PDFs (>100 pages): 1-2 minutes
- **Much faster than docling** (10-50x speedup)

**Error Handling:**

0. **pdftotext not available:**
   - Check with: `which pdftotext` or `command -v pdftotext`
   - Install if needed: `apt-get install poppler-utils` (Debian/Ubuntu)
   - Fallback: Use Read tool to read PDF directly

1. **Docling container not running:**
   - Check with: `docker ps | grep docling`
   - Start if needed: `docker start docling-server` (or run the initial docker run command)

2. **Synchronous conversion timeout ("Conversion is taking too long"):**
   - Automatically retry with asynchronous conversion
   - This is expected for PDFs >10 pages

3. **JSON response structure differences:**
   - Synchronous: `data['md_content']` (top-level key)
   - Asynchronous: `data['document']['md_content']` (nested key)
   - Always check for both structures when parsing

4. **Markdown file too large (>256KB) for Read tool:**
   - Use Grep to extract headings: `grep "^#{1,3}\s+" file.md`
   - Understand document structure from headings
   - Read only necessary sections using Read tool with offset/limit
   - Large file size often due to base64-encoded images in Markdown

5. **Conversion fails entirely:**
   - Fall back to Read tool for direct PDF reading
   - Log conversion errors for debugging
   - Note in output that Markdown conversion was not available

6. **Task status stuck in "pending" or "started":**
   - Continue polling for up to 10 minutes
   - If still stuck, check docling container logs: `docker logs docling-server`
   - Consider restarting container if necessary

**Other Rules:**
- **Empty content detection**: Skip if only cover page, images without captions, or data tables without context
- **Parallel downloads**: Avoid; use sequential downloads to prevent rate limiting

### Quality Requirements

- **No speculation**: Only use information actually present in documents
- **No metadata**: Exclude file sizes, software requirements, timestamps
- **Verification**: Check for actual participant quotes in meeting minutes (「○○大臣」「○○委員」)
- **Absolute URLs**: Convert all relative PDF links to absolute URLs in output

## File Organization

### Project Structure

```
.
├── .claude/
│   ├── commands/
│   │   └── bluesky-post.md          # Bluesky posting command
│   ├── skills/
│   │   ├── pagereport-cas/          # Internal Cabinet Office skill
│   │   │   └── SKILL.md
│   │   ├── pagereport-cao/          # Cabinet Office skill
│   │   │   └── SKILL.md
│   │   ├── pagereport-meti/         # METI skill
│   │   │   └── SKILL.md
│   │   └── common/
│   │       └── base_workflow.md     # Shared workflow (11 steps)
│   └── settings.local.json          # Tool permissions
├── output/
│   └── {meeting_name}_{round}_{date}_report.md
└── CLAUDE.md                        # This file
```

### Output Files

```
output/
└── {meeting_name}_第{N}回_{YYYYMMDD}_report.md
```

Example:
```
output/
└── 日本成長戦略会議_第2回_20251224_report.md
```

**Report File Structure:**
- Header with meeting metadata (name, date, location)
- **Abstract section** (enclosed in code fences for easy extraction by `/bluesky-post`)
- Material list
- Detailed information sections
- Summary and reference links

## Modification Guidelines

### When Editing Workflow (`.claude/skills/common/base_workflow.md`)

- Maintain the 11-step structure for clarity
- Update token optimization strategies if processing different document types
- Adjust PDF scoring criteria based on observed relevance patterns
- Keep abstract structure strict (5 elements, 1 paragraph, 1,000 chars)
- Test with actual government meeting pages to validate changes
- Ensure all PDF URLs are converted to absolute paths

### When Editing Commands (`.claude/commands/`)

- Keep commands focused on a single responsibility
- Document all parameters and error conditions
- Provide usage examples
- Include comprehensive error handling
- Test commands independently before integration

### When Adding New Skills

- Create new skill file in `.claude/skills/<skill-name>/SKILL.md`
- Reference the common workflow: `../common/base_workflow.md`
- Add domain-specific customizations as needed
- Update `.claude/settings.local.json` for domain permissions
- Document in CLAUDE.md

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

## Bluesky Integration

### Overview

The pagereport skills automatically post generated abstracts to Bluesky after completing the report. This enables real-time sharing of government meeting summaries with a wider audience.

A standalone `/bluesky-post` command is also available for manually posting existing reports.

### Setup

**Prerequisites:**
- Install ssky: `pip install ssky`
- Login to Bluesky: `ssky login`
- Enter your Bluesky handle and app password when prompted

**Verification:**
```bash
# Check if ssky is installed
which ssky

# Verify login status
ssky profile

# Should display your profile information
```

### How It Works

**Automatic Posting (Step 11 in pagereport workflow):**
1. After generating report.md, automatically invokes the bluesky-post command
2. Extracts the abstract from the generated report file
3. Posts the abstract (including URL) to Bluesky using `ssky post`
4. Handles long content by automatic thread splitting
5. Gracefully skips if not logged in or if posting fails

**Manual Posting (`/bluesky-post` command):**
- Defined in `.claude/commands/bluesky-post.md`
- Can be invoked independently: `/bluesky-post <report_file_path>`
- Useful for posting existing reports or re-posting

**What gets posted:**
- The complete abstract (論文形式, 1,000 characters)
- Original meeting page URL
- Automatically split into thread if exceeds Bluesky's character limit

### Error Handling

The Bluesky posting step is **non-critical** and will not block report generation:

1. **ssky not installed**: Warning message, posting skipped
2. **Not logged in**: Warning message with login instructions, posting skipped
3. **Posting fails**: Warning message, report saved successfully

In all cases, the report file is generated successfully in `./output/` regardless of posting status.

### Manual Posting

If automatic posting is skipped, you can use the `/bluesky-post` command:

```bash
# Use the command (recommended)
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"

# Or extract and post manually with bash
REPORT_FILE="output/{meeting_name}_{round}_{date}_report.md"
awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE" | ssky post

# Dry run to preview before posting
awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE" | ssky post -d
```

### Disabling Bluesky Posting

To disable Bluesky posting entirely:
1. Logout from ssky: The skill will automatically skip posting if not logged in
2. Or modify the base_workflow.md to comment out Step 11

### Character Limit Handling

Bluesky has a 300 grapheme limit per post. The ssky tool automatically handles this:
- Long abstracts (1,000 characters) are automatically split into thread posts
- Each post in the thread maintains context
- URL is included in the final post of the thread

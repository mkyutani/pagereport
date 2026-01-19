# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code skills project for generating structured summaries of Japanese government meeting pages. The main skill (`pagereport`) processes both HTML pages and PDF documents from government websites, extracting metadata, analyzing meeting materials, and producing a unified report file:

**Report file** (`*_report.md`): Markdown report containing a 1,000-character abstract (enclosed in code fences for easy extraction) + material list + comprehensive details up to 10,000 characters for future reference

## Architecture

### Orchestrator Pattern

This project uses an **orchestrator pattern** where the main workflow delegates all processing to specialized subagents:

- **Orchestrator**: `.claude/skills/common/base_workflow.md`
  - Lightweight workflow coordinator (686 lines, reduced from 955)
  - Manages 11-step processing flow
  - Calls subagents via Task tool
  - Handles data transformation between steps
  - Manages parallel execution (Steps 6, 7, 8)
  - Error handling based on error levels (CRITICAL/MAJOR/MINOR)

- **Subagents**: `.claude/agents/` (11 total)
  - Each subagent is a self-contained processing unit
  - JSON input/output for standardization
  - Automatic completion without user confirmation
  - Independent testing and maintenance

**Benefits of Orchestrator Pattern:**
- **Token Optimization**: Only load necessary subagent files (60-80% reduction)
- **Parallel Execution**: 67% faster processing (9min vs 27min)
- **Maintainability**: Each component can be updated independently
- **Reusability**: Subagents can be used in other projects

### Core Components

**Skills**: `.claude/skills/`
- `pagereport-cas/`: Internal Cabinet Office (内閣府)
- `pagereport-cao/`: Cabinet Office (総務省)
- `pagereport-meti/`: Ministry of Economy, Trade and Industry (経済産業省)
- `pagereport-chusho/`: Small and Medium Enterprise Agency (中小企業庁)
- `pagereport-mhlw/`: Ministry of Health, Labour and Welfare (厚生労働省)
- `pagereport-fsa/`: Financial Services Agency (金融庁)
- `pagereport-digital/`: Digital Agency (デジタル庁)
- `bluesky-post/`: Bluesky posting skill (auto-execute: true)
- `github-workflow/`: GitHub workflow rules for commits and pull requests
- `common/base_workflow.md`: **Orchestrator** that coordinates all 11 steps

**Subagents**: `.claude/agents/` (11 subagents for 11 steps)

All subagents are invoked via the **Task tool** (not Skill tool) for automatic execution without user confirmation.

1. **content-acquirer** (Step 1): HTML/PDF acquisition and PDF link extraction
2. **metadata-extractor** (Step 2): Meeting metadata extraction
3. **page-type-detector** (Step 2.5): Page type detection
4. **overview-creator** (Step 3): Meeting overview creation
5. **minutes-referencer** (Step 4): Minutes extraction
6. **material-selector** (Step 5): Material prioritization and download
7. **document-type-classifier** (Step 6): Document type detection (parallel)
8. **pdf-converter** (Step 7): PDF to text/Markdown conversion (parallel)
9. **material-analyzer** (Step 8): Material analysis (parallel)
10. **summary-generator** (Step 9): Abstract and report generation
11. **file-writer** (Step 10): Report file output

**Subagent Error Handling:**
- **If subagents are unavailable**: Processing will terminate with error message
- **Error Levels**:
  - `CRITICAL`: Stop processing (e.g., HTML fetch failure)
  - `MAJOR`: Skip step and continue (e.g., minutes not found)
  - `MINOR`: Warning only (e.g., Bluesky post failure)

**Shell Scripts**: `.claude/skills/common/scripts/`

All complex Bash operations are externalized to shell scripts for better maintainability and automatic execution.

**Common Scripts**:
- `download_pdf.sh`, `download_pdf_with_useragent.sh`: PDF download
- `convert_pdftotext.sh`, `convert_pdftotext_fallback.sh`: pdftotext conversion
- `docling_convert_async.sh`, `docling_poll_status.sh`, `docling_get_result.sh`: docling conversion
- `extract_images_from_md.sh`: Extract base64 images from Markdown
- `extract_important_pages.sh`: Extract important pages
- `check_tool.sh`: Check if a tool is available

**Step-Specific Scripts**:
- `make_absolute_urls.py`: Convert relative PDF URLs to absolute URLs
- `convert_era_to_western.py`, `normalize_meeting_name.py`: Date/name normalization
- `extract_speakers.py`: Extract speakers from minutes
- `classify_document.py`: Classify PDFs by type
- `validate_abstract_structure.py`: Validate 5-element abstract structure
- `validate_filename.py`, `create_output_directory.sh`: File operations

**Permissions**: `.claude/settings.local.json`
- **Pre-authorized shell script execution**: `Bash(bash:*)`, `Bash(sh:*)` - enables all scripts in `.claude/skills/common/scripts/`
- Pre-authorized Bash commands: `curl`, `mkdir`, `ls`, `grep`, `wc`, `cat`, `head`, `tail`, `which`, `command`, `sleep`, `python3`, `pdftotext`, `docker`, `awk`, `ssky`, `chmod`, `wget`
- Pre-authorized WebFetch domains: `github.com`, `*.go.jp`
- Pre-authorized file operations: `Read/Write/Edit(path:./tmp/*)`, `Read/Write/Edit(path:./output/*)`
- Pre-authorized skills: All pagereport skills, bluesky-post
- **Pre-authorized Task tool subagents** (all 11): content-acquirer, metadata-extractor, page-type-detector, overview-creator, minutes-referencer, material-selector, document-type-classifier, pdf-converter, material-analyzer, summary-generator, file-writer
- These permissions enable fully automatic workflow execution without user confirmation prompts

### Processing Pipeline

The skill follows a structured 11-step workflow:

1. **Content Acquisition**: Fetch HTML with WebFetch or read local/remote PDFs
2. **Metadata Extraction**: Auto-extract meeting name, date (converted to YYYYMMDD), round number, location
3. **Meeting Overview Creation**: Extract from HTML or agenda PDF
4. **Minutes Reference**: Locate actual participant statements if available
5. **Material Selection and Download**: Score PDFs (1-5) by relevance, download top-priority files to `./tmp/`
6. **Document Type Detection** (Parallel): Classify PDFs as Word/PowerPoint/Other from first 5 pages
7. **PDF to Markdown Conversion** (Parallel): Convert with docling (PowerPoint) or pdftotext (Word) for token optimization
8. **Type-Specific Reading** (Parallel): Apply token-optimized strategies based on document type and page count
9. **Summary Generation**: Create structured abstract (1,000 chars, 5-element structure) + detailed report
10. **File Output**: Write to `{meeting_name}_{round}_{date}_report.md` with abstract enclosed in code fences
11. **Bluesky Posting**: Automatically post the abstract to Bluesky using `ssky post` command

### Key Design Principles

**Parallel Processing:** Steps 6, 7, 8 run multiple subagents in parallel (one per PDF/material) using multiple `Task(subagent_type: "...")` calls in single message. Reduces processing time by 30-50%.

**Token Optimization:** Dynamic reading strategies based on page count (≤5: full text, >50: metadata + ToC only). Use docling (PowerPoint) or pdftotext (Word). Skip low-priority materials.

**PDF Prioritization:** Score PDFs 1-5 by relevance, importance, document type. Filename pattern recognition (`shiryou1.pdf` > `sankou*.pdf`). Cross-reference with meeting minutes.

**Abstract Structure (論文形式, 1,000 chars max):**
1. Background/Context (2-3 sentences) - Must include meeting name and round number
2. Purpose (1-2 sentences)
3. Discussion Content (3-5 sentences)
4. Decisions/Agreements (3-5 sentences)
5. Future Direction (2-3 sentences)
- Single paragraph, factual only, URL on new line after paragraph

## Usage

**Run skill with URL:**
```bash
/pagereport-cas "https://www.cas.go.jp/..."
/pagereport-cao "https://www.cao.go.jp/..."
/pagereport-meti "https://www.meti.go.jp/..."
/pagereport-chusho "https://www.chusho.meti.go.jp/..."
/pagereport-mhlw "https://www.mhlw.go.jp/..."
/pagereport-fsa "https://www.fsa.go.jp/..."
/pagereport-digital "https://www.digital.go.jp/..."
```

Automatically extracts metadata, downloads PDFs to `./tmp/`, generates report in `./output/`, posts to Bluesky (if logged in).

**Manual Bluesky posting:**
```bash
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

## Important Implementation Notes

### Error Handling

- **Subagent unavailable**: Terminate with error. Check YAML frontmatter and permissions in `.claude/settings.local.json`
- **HTML fetch failure**: Retry with normalization, log each stage
- **PDF download/read failure**: Log error, skip file, mark as "failed" or "unreadable"
- **Missing metadata**: Prompt user for meeting name, date, or round number
- **Bluesky posting failure**: Log warning, continue (non-critical)

### Content Cleaning (HTML)

**Remove**: Headers, footers, sidebars, breadcrumbs, navigation, ads, auxiliary content
**Preserve**: Meeting minutes, reports, agendas, decisions, essential content (headings, lists, tables, links)

### PDF Processing Rules

**PDF Acquisition:**
- Remote PDFs: Download to `./tmp/` sequentially (no parallel downloads)
- Local PDFs: Read directly with Read tool

**Document Type-Based Processing (Step 6):**
- **PowerPoint PDFs** → docling conversion (`docling_convert_async.sh`, `docling_poll_status.sh`, `docling_get_result.sh`)
  - After conversion: Run `extract_images_from_md.sh` to remove base64 images
- **Word PDFs** → pdftotext conversion (`convert_pdftotext.sh`, fallback: `convert_pdftotext_fallback.sh`)
- **Other PDFs** → Size-based: <20 pages (Read tool), 20-50 pages (pdftotext), >50 pages (pdftotext + offset/limit)

**Error Handling:**
- Tool unavailable: Check with `check_tool.sh`, fallback to Read tool
- Conversion fails: Fall back to Read tool for direct PDF reading

### Quality Requirements

- **No speculation**: Only use information actually present in documents
- **No metadata**: Exclude file sizes, software requirements, timestamps
- **Verification**: Check for actual participant quotes in meeting minutes (「○○大臣」「○○委員」)
- **Absolute URLs**: Convert all relative PDF links to absolute URLs in output

## File Organization

**Key Directories:**
- `.claude/agents/`: 11 subagents (one per processing step)
- `.claude/skills/`: pagereport-* (6 agencies), bluesky-post, github-workflow
- `.claude/skills/common/`: base_workflow.md (orchestrator), scripts/ (shell scripts)
- `.claude/docs/`: subagent-conventions.md
- `.claude/settings.local.json`: Tool permissions
- `output/`: Generated report files

**Output Format:** `{meeting_name}_第{N}回_{YYYYMMDD}_report.md`

Example: `日本成長戦略会議_第2回_20251224_report.md`

## Modification Guidelines

**Editing Workflow:** Maintain 11-step structure. Keep abstract structure strict (5 elements, 1,000 chars). Test with actual government meeting pages.

**Adding New Skills:** Create `.claude/skills/<skill-name>/SKILL.md`. Reference `../common/base_workflow.md`. Update `.claude/settings.local.json` for permissions.

**Commits/PRs:** Reference `.claude/skills/github-workflow/SKILL.md`. Use Conventional Commits format. No "Generated with Claude Code" footers. Never commit directly to main.

## Troubleshooting

**Subagent Not Found:** Check `.claude/agents/{name}.md` has YAML frontmatter. Verify permission in `.claude/settings.local.json`: `"Task(subagent_type:{name})"`

**JSON Parsing Error:** Ensure subagent outputs ONLY valid JSON (no explanatory text).

**Token Overflow:** Process materials in batches (max 3 parallel). Use Read tool with limit/offset for large files.

**Docling Container Issues:** Check `docker ps | grep docling`. Fix: `docker start docling-server`

**Script Execution Failure:** `chmod +x .claude/skills/common/scripts/**/*.{sh,py}`

## Bluesky Integration

**Automatic Posting (Step 11):**
- Extracts abstract from generated report file
- Posts to Bluesky using `ssky post`
- Handles long content by automatic thread splitting
- Gracefully skips if not logged in or if posting fails

**Manual Posting:**
```bash
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

**Error Handling:**
- The Bluesky posting step is **non-critical** and will not block report generation
- If ssky not installed, not logged in, or posting fails: Warning message, report saved successfully

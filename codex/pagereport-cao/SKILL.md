---
name: pagereport-cao
description: Generate a summary report for Cabinet Office meeting pages (HTML and PDF).
---

# Pagereport CAO

## Scope
- Domain: www8.cao.go.jp
- Agency id: cao

## HTML fetch (step 1)
Use WebFetch, clean HTML, extract and absolutize PDF links.

## PDF download (step 5)
Use the standard downloader:
```
bash ../common/scripts/download_pdf.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

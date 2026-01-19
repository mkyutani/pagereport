---
name: pagereport-mhlw
description: Generate a summary report for MHLW meeting pages (HTML and PDF) with User-Agent for downloads.
---

# Pagereport MHLW

## Scope
- Domain: www.mhlw.go.jp
- Agency id: mhlw

## HTML fetch (step 1)
WebFetch is allowed for HTML pages.

## PDF download (step 5)
Use the User-Agent downloader:
```
bash ../common/scripts/download_pdf_with_useragent.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

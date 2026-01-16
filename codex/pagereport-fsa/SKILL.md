---
name: pagereport-fsa
description: Generate a summary report for FSA meeting pages (HTML and PDF) with User-Agent for downloads.
---

# Pagereport FSA

## Scope
- Domain: www.fsa.go.jp
- Agency id: fsa

## HTML fetch (step 1)
WebFetch is allowed for HTML pages.

## PDF download (step 5)
Use the User-Agent downloader:
```
bash ../common/scripts/download_pdf_with_useragent.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

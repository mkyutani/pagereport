---
name: pagereport-digital
description: Generate a summary report for Digital Agency meeting pages (HTML and PDF).
---

# Pagereport Digital

## Scope
- Domain: www.digital.go.jp
- Agency id: digital

## HTML fetch (step 1)
Use WebFetch, clean HTML, extract and absolutize PDF links.

## PDF download (step 5)
Use the standard downloader:
```
bash ../common/scripts/download_pdf.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

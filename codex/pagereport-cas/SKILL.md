---
name: pagereport-cas
description: Generate a summary report for Cabinet Secretariat meeting pages (HTML and PDF).
---

# Pagereport CAS

## Scope
- Domain: www.cas.go.jp
- Agency id: cas

## HTML fetch (step 1)
Use WebFetch, clean HTML, extract and absolutize PDF links.

## PDF download (step 5)
Use the standard downloader:
```
bash ../common/scripts/download_pdf.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

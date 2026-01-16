---
name: pagereport-meti
description: Generate a summary report for METI meeting pages (HTML and PDF) with required User-Agent.
---

# Pagereport METI

## Scope
- Domain: www.meti.go.jp
- Agency id: meti

## HTML fetch (step 1)
Do not use WebFetch. The site requires a User-Agent. Use curl and read the saved HTML.
```
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  "https://www.meti.go.jp/..." > ./tmp/meti_page.html
```

## PDF download (step 5)
Use the User-Agent downloader:
```
bash ../common/scripts/download_pdf_with_useragent.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

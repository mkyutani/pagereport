---
name: pagereport-chusho
description: Generate a summary report for SME Agency meeting pages (HTML and PDF) with required User-Agent.
---

# Pagereport Chusho

## Scope
- Domain: www.chusho.meti.go.jp
- Agency id: chusho

## HTML fetch (step 1)
Do not use WebFetch. Use the dedicated fetch script with a User-Agent:
```
bash ../common/scripts/fetch_html_with_useragent.sh \
  "https://www.chusho.meti.go.jp/..." \
  "./tmp/chusho_page.html"
```

## PDF download (step 5)
Use the User-Agent downloader:
```
bash ../common/scripts/download_pdf_with_useragent.sh "<URL>" "./tmp/<filename>"
```

## Workflow
Run the pagereport orchestrator and include the agency-specific instructions above in the step prompts.

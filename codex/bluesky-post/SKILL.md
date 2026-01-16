---
name: bluesky-post
description: Extract the abstract from a report file and post it to Bluesky.
---

# Bluesky Post

## Input
- Report file path, absolute or relative

## Command
```
bash scripts/post.sh "<report_file_path>"
```

## Notes
- Requires `ssky` installed and logged in.
- Posting is best-effort and non-blocking.

#!/bin/bash
# Markdownから重要ページのみを抽出
#
# Usage: bash extract_important_pages.sh <INPUT_MD> <OUTPUT_MD> <PAGE_NUMBERS>
# Example: bash extract_important_pages.sh "/tmp/doc_full.md" "/tmp/doc.md" "3,4,5,6,7,10,12,15"

set -e

if [ $# -lt 3 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <INPUT_MD> <OUTPUT_MD> <PAGE_NUMBERS>" >&2
    echo "Example: $0 input.md output.md '3,4,5,6,7'" >&2
    exit 1
fi

INPUT_MD="$1"
OUTPUT_MD="$2"
PAGE_NUMBERS="$3"

if [ ! -f "$INPUT_MD" ]; then
    echo "Error: Input file not found: $INPUT_MD" >&2
    exit 1
fi

echo "Extracting important pages from: $INPUT_MD" >&2
echo "Page numbers: $PAGE_NUMBERS" >&2

python3 << 'EOF'
import re
import sys

input_md = sys.argv[1]
output_md = sys.argv[2]
page_numbers_str = sys.argv[3]

# Parse page numbers
important_pages = set(int(p.strip()) for p in page_numbers_str.split(','))

# Read Markdown content
with open(input_md, 'r', encoding='utf-8') as f:
    content = f.read()

# Split by page markers
# Handles both "## Page N" and "<!-- page N -->" formats
pages = re.split(r'(?:##\s*Page\s*(\d+)|<!--\s*page\s*(\d+)\s*-->)', content, flags=re.IGNORECASE)

# Extract important pages
important_content = []
i = 0
while i < len(pages):
    # Check if this is a page marker match
    if i > 0 and (pages[i] or (i+1 < len(pages) and pages[i+1])):
        page_num_str = pages[i] if pages[i] else pages[i+1]
        if page_num_str and page_num_str.isdigit():
            page_num = int(page_num_str)
            # Get content (next element after page number matches)
            content_idx = i + 2 if pages[i] else i + 3
            if content_idx < len(pages) and page_num in important_pages:
                page_content = pages[content_idx]
                important_content.append(f'## Page {page_num}\n{page_content}')
                print(f'Extracted page {page_num}', file=sys.stderr)
    i += 1

# Write important pages
with open(output_md, 'w', encoding='utf-8') as f:
    f.write('\n\n---\n\n'.join(important_content))

print(f'Extracted {len(important_content)} important pages', file=sys.stderr)
EOF "$INPUT_MD" "$OUTPUT_MD" "$PAGE_NUMBERS"

if [ -f "$OUTPUT_MD" ]; then
    LINE_COUNT=$(wc -l < "$OUTPUT_MD")
    echo "Output saved: $LINE_COUNT lines" >&2
else
    echo "Error: Failed to create output file" >&2
    exit 1
fi

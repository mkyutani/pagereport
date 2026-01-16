#!/bin/bash
# PDFをテキストに変換（PyPDF2フォールバック）
# pdftotextが使えない場合のフォールバック
#
# Usage: bash convert_pdftotext_fallback.sh <PDF_FILE> <OUTPUT_FILE>
# Example: bash convert_pdftotext_fallback.sh "/tmp/doc.pdf" "/tmp/doc.txt"

set -e

if [ $# -lt 2 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <PDF_FILE> <OUTPUT_FILE>" >&2
    exit 1
fi

PDF_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file not found: $PDF_FILE" >&2
    exit 1
fi

echo "Converting PDF to text using PyPDF2: $PDF_FILE" >&2

python3 << EOF
from PyPDF2 import PdfReader

reader = PdfReader('$PDF_FILE')
text_content = []
for page in reader.pages:
    text_content.append(page.extract_text())

with open('$OUTPUT_FILE', 'w', encoding='utf-8') as f:
    f.write('\n'.join(text_content))
EOF

if [ -f "$OUTPUT_FILE" ]; then
    LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
    echo "Conversion complete: $LINE_COUNT lines" >&2
else
    echo "Error: Conversion failed" >&2
    exit 1
fi

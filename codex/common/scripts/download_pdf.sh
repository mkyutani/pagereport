#!/bin/bash
# PDFダウンロードスクリプト（通常版）
#
# Usage: bash download_pdf.sh <URL> <OUTPUT_FILE>
# Example: bash download_pdf.sh "https://example.com/doc.pdf" "/tmp/doc.pdf"

set -e

if [ $# -lt 2 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <URL> <OUTPUT_FILE>" >&2
    exit 1
fi

URL="$1"
OUTPUT_FILE="$2"

echo "Downloading PDF from: $URL" >&2
echo "Saving to: $OUTPUT_FILE" >&2

curl -o "$OUTPUT_FILE" "$URL"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    echo "Download complete: $FILE_SIZE bytes" >&2
else
    echo "Error: Download failed" >&2
    exit 1
fi

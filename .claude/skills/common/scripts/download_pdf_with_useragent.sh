#!/bin/bash
# PDFダウンロードスクリプト（User-Agent付き）
# METI/Chushoなど、User-Agentチェックを行うサイト用
#
# Usage: bash download_pdf_with_useragent.sh <URL> <OUTPUT_FILE>
# Example: bash download_pdf_with_useragent.sh "https://www.meti.go.jp/doc.pdf" "/tmp/doc.pdf"

set -e

if [ $# -lt 2 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <URL> <OUTPUT_FILE>" >&2
    exit 1
fi

URL="$1"
OUTPUT_FILE="$2"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

echo "Downloading PDF from: $URL" >&2
echo "Saving to: $OUTPUT_FILE" >&2
echo "Using User-Agent: Chrome" >&2

curl -A "$USER_AGENT" -o "$OUTPUT_FILE" "$URL"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    echo "Download complete: $FILE_SIZE bytes" >&2
else
    echo "Error: Download failed" >&2
    exit 1
fi

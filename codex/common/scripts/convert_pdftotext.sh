#!/bin/bash
# PDFをテキストに変換（pdftotext使用）
#
# Usage: bash convert_pdftotext.sh <PDF_FILE> <OUTPUT_FILE>
# Example: bash convert_pdftotext.sh "/tmp/doc.pdf" "/tmp/doc.txt"

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

# Check if pdftotext is available
if ! command -v pdftotext &> /dev/null; then
    echo "Error: pdftotext not found. Please install poppler-utils." >&2
    exit 1
fi

echo "Converting PDF to text: $PDF_FILE" >&2
pdftotext "$PDF_FILE" "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
    echo "Conversion complete: $LINE_COUNT lines" >&2
else
    echo "Error: Conversion failed" >&2
    exit 1
fi

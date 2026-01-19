#!/bin/bash
# docling非同期変換を開始してTASK_IDを返す
#
# Usage: bash docling_convert_async.sh <PDF_FILE>
# Example: bash docling_convert_async.sh "/tmp/doc.pdf"
# Output: TASK_ID (stdout)

set -e

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <PDF_FILE>" >&2
    exit 1
fi

PDF_FILE="$1"

if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file not found: $PDF_FILE" >&2
    exit 1
fi

echo "Starting docling async conversion: $PDF_FILE" >&2

TASK_ID=$(curl -s -X POST http://localhost:5001/v1/convert/file/async \
  -F "files=@$PDF_FILE" | \
  python3 -c "import json, sys; print(json.load(sys.stdin)['task_id'])")

if [ -z "$TASK_ID" ]; then
    echo "Error: Failed to get TASK_ID" >&2
    exit 1
fi

echo "TASK_ID: $TASK_ID" >&2
echo "$TASK_ID"  # Output to stdout for capture

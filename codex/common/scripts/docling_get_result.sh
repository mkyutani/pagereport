#!/bin/bash
# docling変換結果を取得してMarkdownファイルに保存
#
# Usage: bash docling_get_result.sh <TASK_ID> <OUTPUT_FILE>
# Example: bash docling_get_result.sh "abc123" "/tmp/doc.md"

set -e

if [ $# -lt 2 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <TASK_ID> <OUTPUT_FILE>" >&2
    exit 1
fi

TASK_ID="$1"
OUTPUT_FILE="$2"

echo "Retrieving result for TASK_ID: $TASK_ID" >&2

curl -s "http://localhost:5001/v1/result/$TASK_ID" | \
  python3 -c "import json, sys; print(json.load(sys.stdin)['document']['md_content'])" \
  > "$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    echo "Result saved: $FILE_SIZE bytes" >&2
else
    echo "Error: Failed to save result" >&2
    exit 1
fi

#!/bin/bash
# docling変換ステータスをポーリングして完了を待つ
#
# Usage: bash docling_poll_status.sh <TASK_ID>
# Example: bash docling_poll_status.sh "abc123"
# Output: "success" or "failure" (stdout)

set -e

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <TASK_ID>" >&2
    exit 1
fi

TASK_ID="$1"
MAX_ATTEMPTS=40  # 40 attempts * 15 seconds = 10 minutes max
ATTEMPT=0

echo "Polling status for TASK_ID: $TASK_ID" >&2

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    STATUS=$(curl -s "http://localhost:5001/v1/status/poll/$TASK_ID" | \
        python3 -c "import json, sys; print(json.load(sys.stdin)['task_status'])")

    echo "Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS - Status: $STATUS" >&2

    if [ "$STATUS" = "success" ]; then
        echo "Conversion successful" >&2
        echo "success"
        exit 0
    elif [ "$STATUS" = "failure" ]; then
        echo "Conversion failed" >&2
        echo "failure"
        exit 1
    fi

    ATTEMPT=$((ATTEMPT+1))
    sleep 15
done

echo "Error: Polling timeout after $((MAX_ATTEMPTS * 15)) seconds" >&2
exit 1

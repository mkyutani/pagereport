#!/bin/bash
# ツールの存在を確認
#
# Usage: bash check_tool.sh <TOOL_NAME>
# Example: bash check_tool.sh pdftotext
# Exit code: 0 if found, 1 if not found

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments" >&2
    echo "Usage: $0 <TOOL_NAME>" >&2
    exit 1
fi

TOOL_NAME="$1"

if command -v "$TOOL_NAME" &> /dev/null; then
    TOOL_PATH=$(command -v "$TOOL_NAME")
    echo "Found: $TOOL_PATH" >&2
    exit 0
else
    echo "Not found: $TOOL_NAME" >&2
    exit 1
fi

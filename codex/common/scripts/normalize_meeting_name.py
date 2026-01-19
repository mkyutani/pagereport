#!/usr/bin/env python3
"""
会議名から不要な文字列（「第X回」など）を削除して正規化するスクリプト
"""

import re
import sys


def normalize_meeting_name(raw_name):
    """会議名から不要な文字列を削除"""

    # 「第X回」を削除
    name = re.sub(r'第\d+回\s*', '', raw_name)
    name = re.sub(r'第（\d+）回\s*', '', name)

    # 「（第X回）」を削除
    name = re.sub(r'[（(]第\d+回[）)]\s*', '', name)

    # 前後の空白を削除
    name = name.strip()

    return name


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: normalize_meeting_name.py <raw_name>", file=sys.stderr)
        sys.exit(1)

    raw_name = sys.argv[1]
    normalized = normalize_meeting_name(raw_name)

    print(normalized)

#!/usr/bin/env python3
"""
議事録から発言者を抽出して集計するスクリプト
"""

import json
import re
import sys


def extract_speakers(minutes_text):
    """発言者を抽出して集計"""

    # 発言者パターン
    pattern = r'(○○[^\s：:]+)[：:]\s*'

    speakers = {}
    for match in re.finditer(pattern, minutes_text):
        name = match.group(1)
        speakers[name] = speakers.get(name, 0) + 1

    # 配列形式に変換
    result = [
        {"name": name, "statement_count": count}
        for name, count in speakers.items()
    ]

    # 発言回数でソート
    result.sort(key=lambda x: x['statement_count'], reverse=True)

    return result


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: extract_speakers.py <minutes_text>", file=sys.stderr)
        sys.exit(1)

    minutes_text = sys.argv[1]
    speakers = extract_speakers(minutes_text)

    print(json.dumps(speakers, ensure_ascii=False, indent=2))

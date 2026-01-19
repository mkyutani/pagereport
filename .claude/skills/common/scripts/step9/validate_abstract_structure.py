#!/usr/bin/env python3
"""
アブストラクトの5要素構造を検証するスクリプト
"""

import json
import re
import sys


def validate_abstract_structure(abstract_text):
    """アブストラクトの5要素構造を検証"""

    validation = {
        "has_background": False,
        "has_purpose": False,
        "has_discussion": False,
        "has_decisions": False,
        "has_future_direction": False
    }

    # 背景: 会議名と回数が含まれているか
    if re.search(r'第\d+回.*会議', abstract_text):
        validation["has_background"] = True

    # 目的: 「目的」「目指す」などのキーワード
    if any(kw in abstract_text for kw in ['目的', '目指す', '検討', '実現']):
        validation["has_purpose"] = True

    # 議論: 「議題」「資料」「提示」などのキーワード
    if any(kw in abstract_text for kw in ['議題', '資料', '提示', '議論']):
        validation["has_discussion"] = True

    # 決定: 「決定」「予算」「制度」などのキーワード
    if any(kw in abstract_text for kw in ['決定', '予算', '制度', '措置', '確定']):
        validation["has_decisions"] = True

    # 今後: 「今後」「指示」「推進」などのキーワード
    if any(kw in abstract_text for kw in ['今後', '指示', '推進', '予定', '方針']):
        validation["has_future_direction"] = True

    return validation


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: validate_abstract_structure.py <abstract_text>", file=sys.stderr)
        sys.exit(1)

    abstract_text = sys.argv[1]
    validation = validate_abstract_structure(abstract_text)

    print(json.dumps(validation, ensure_ascii=False, indent=2))

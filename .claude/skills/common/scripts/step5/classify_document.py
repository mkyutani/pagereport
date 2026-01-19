#!/usr/bin/env python3
"""
PDFのタイトルとファイル名から文書カテゴリを判定するスクリプト
"""

import re
import sys


def has_personal_or_organization_name(title):
    """個人名・団体名を含むかを判定"""

    # 個人名パターン
    personal_patterns = [
        r'○○委員',
        r'○○教授',
        r'○○氏',
        r'○○先生'
    ]

    # 団体名パターン
    organization_patterns = [
        r'株式会社',
        r'社団法人',
        r'財団法人',
        r'一般社団法人',
        r'公益財団法人',
        r'大学',
        r'研究所'
    ]

    all_patterns = personal_patterns + organization_patterns

    for pattern in all_patterns:
        if re.search(pattern, title):
            return True

    return False


def classify_document(title, filename):
    """文書カテゴリを判定"""

    title_lower = title.lower()
    filename_lower = filename.lower()

    # 議事次第
    if any(kw in title for kw in ['議事次第', '次第']):
        return 'agenda'

    # 議事録
    if any(kw in title for kw in ['議事録', '議事要旨', '会議録']):
        return 'minutes'

    # 除外対象
    if any(kw in title for kw in ['委員名簿', '出席者名簿']):
        return 'participants'

    if any(kw in title for kw in ['座席表', '座席配置']):
        return 'seating'

    if any(kw in title for kw in ['公開方法', '傍聴']):
        return 'disclosure_method'

    # Executive Summary
    if any(kw in title for kw in ['とりまとめ', '概要', 'Executive Summary', 'エグゼクティブサマリー']):
        return 'executive_summary'

    # 参考資料
    if any(kw in filename_lower for kw in ['sankou', '参考']):
        return 'reference'

    # 個人名・団体名
    if has_personal_or_organization_name(title):
        return 'personal_material'

    # 通常資料
    if re.match(r'資料\d+', title):
        return 'material'

    return 'other'


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: classify_document.py <title> <filename>", file=sys.stderr)
        sys.exit(1)

    title = sys.argv[1]
    filename = sys.argv[2]

    category = classify_document(title, filename)
    print(category)

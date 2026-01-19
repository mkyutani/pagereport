#!/usr/bin/env python3
"""
元号（令和・平成）を西暦YYYYMMDD形式に変換するスクリプト
"""

import re
import sys


def convert_to_western_year(era, year, month, day):
    """
    元号を西暦に変換

    令和: 2019年5月1日開始
    令和X年 = 2018 + X年

    平成: 1989年1月8日開始
    平成X年 = 1988 + X年
    """
    if era == "令和":
        western_year = 2018 + year
    elif era == "平成":
        western_year = 1988 + year
    else:
        # 西暦の場合はそのまま
        western_year = year

    # YYYYMMDD形式に整形
    return f"{western_year}{month:02d}{day:02d}"


def extract_and_convert_date(text):
    """日付を抽出して西暦YYYYMMDD形式に変換"""

    # 令和パターン
    pattern = r'令和(\d+)年(\d+)月(\d+)日'
    match = re.search(pattern, text)

    if match:
        year = int(match.group(1))
        month = int(match.group(2))
        day = int(match.group(3))

        # 令和 → 西暦変換
        western_year = 2018 + year
        yyyymmdd = f"{western_year}{month:02d}{day:02d}"
        original = f"令和{year}年{month}月{day}日"

        return {
            "meeting_date": yyyymmdd,
            "meeting_date_original": original,
            "confidence": "high",
            "extraction_source": "text_body"
        }

    # 平成パターン
    pattern = r'平成(\d+)年(\d+)月(\d+)日'
    match = re.search(pattern, text)

    if match:
        year = int(match.group(1))
        month = int(match.group(2))
        day = int(match.group(3))

        # 平成 → 西暦変換
        western_year = 1988 + year
        yyyymmdd = f"{western_year}{month:02d}{day:02d}"
        original = f"平成{year}年{month}月{day}日"

        return {
            "meeting_date": yyyymmdd,
            "meeting_date_original": original,
            "confidence": "high",
            "extraction_source": "text_body"
        }

    # 西暦パターン
    pattern = r'(\d{4})年(\d+)月(\d+)日'
    match = re.search(pattern, text)

    if match:
        year = int(match.group(1))
        month = int(match.group(2))
        day = int(match.group(3))

        yyyymmdd = f"{year}{month:02d}{day:02d}"
        original = f"{year}年{month}月{day}日"

        return {
            "meeting_date": yyyymmdd,
            "meeting_date_original": original,
            "confidence": "high",
            "extraction_source": "text_body"
        }

    return None


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: convert_era_to_western.py <text>", file=sys.stderr)
        sys.exit(1)

    text = sys.argv[1]

    result = extract_and_convert_date(text)

    if result:
        import json
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("Date not found", file=sys.stderr)
        sys.exit(1)

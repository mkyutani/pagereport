#!/usr/bin/env python3
"""
ファイル名が有効かを検証するスクリプト
"""

import sys


def validate_filename(filename):
    """ファイル名が有効かを検証"""

    # 禁止文字をチェック
    invalid_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|']

    for char in invalid_chars:
        if char in filename:
            return False, f"ファイル名に禁止文字が含まれています: {char}"

    # 長さチェック（255文字以内）
    if len(filename) > 255:
        return False, "ファイル名が長すぎます（255文字以内）"

    return True, None


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: validate_filename.py <filename>", file=sys.stderr)
        sys.exit(1)

    filename = sys.argv[1]
    valid, error = validate_filename(filename)

    if valid:
        print("OK")
        sys.exit(0)
    else:
        print(error, file=sys.stderr)
        sys.exit(1)

#!/usr/bin/env python3
"""
PDFリンクの相対URLを絶対URLに変換するスクリプト
"""

import json
import sys
from urllib.parse import urljoin, urlparse


def make_absolute_urls(pdf_links, base_url):
    """相対URLを絶対URLに変換"""
    result = []
    for link in pdf_links:
        absolute_url = urljoin(base_url, link['url'])
        link['url'] = absolute_url

        # ファイル名を抽出
        parsed = urlparse(absolute_url)
        filename = parsed.path.split('/')[-1]
        link['filename'] = filename

        result.append(link)
    return result


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: make_absolute_urls.py <pdf_links_json> <base_url>", file=sys.stderr)
        sys.exit(1)

    pdf_links_json = sys.argv[1]
    base_url = sys.argv[2]

    # JSONを読み込み
    pdf_links = json.loads(pdf_links_json)

    # 絶対URLに変換
    result = make_absolute_urls(pdf_links, base_url)

    # JSON形式で出力
    print(json.dumps(result, ensure_ascii=False, indent=2))

#!/bin/bash
# HTML取得スクリプト（User-Agent付き）
# 中小企業庁などUser-Agentフィルタリングを実装しているサイト用

set -euo pipefail

# 使用方法チェック
if [ "$#" -ne 2 ]; then
    echo "使用方法: $0 <URL> <出力ファイルパス>" >&2
    echo "例: $0 'https://www.chusho.meti.go.jp/...' '/tmp/page.html'" >&2
    exit 1
fi

URL="$1"
OUTPUT_FILE="$2"

# User-Agent文字列
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# HTML取得
echo "HTML取得中: $URL" >&2
if curl -A "$USER_AGENT" \
     -f \
     -s \
     -S \
     --max-time 30 \
     "$URL" > "$OUTPUT_FILE"; then
    echo "取得成功: $OUTPUT_FILE" >&2
    echo "ファイルサイズ: $(wc -c < "$OUTPUT_FILE") bytes" >&2
    exit 0
else
    EXIT_CODE=$?
    echo "エラー: HTML取得に失敗しました (終了コード: $EXIT_CODE)" >&2
    exit $EXIT_CODE
fi

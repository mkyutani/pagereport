#!/bin/bash
# Bluesky投稿スクリプト
# Usage: post.sh <report_file_path>

set -e  # エラーが発生したら即座に終了

REPORT_FILE="$1"

# 引数チェック
if [ -z "$REPORT_FILE" ]; then
    echo "Error: レポートファイルパスが指定されていません" >&2
    echo "Usage: $0 <report_file_path>" >&2
    exit 1
fi

# ファイル存在チェック
if [ ! -f "$REPORT_FILE" ]; then
    echo "Error: レポートファイルが見つかりません: $REPORT_FILE" >&2
    exit 1
fi

# sskyインストールチェック
if ! command -v ssky &> /dev/null; then
    echo "Warning: sskyがインストールされていません。Bluesky投稿をスキップします。" >&2
    echo "インストール方法: pip install ssky" >&2
    exit 0  # 非クリティカルなのでエラーにしない
fi

# sskyログインチェック
if ! ssky profile myself &> /dev/null; then
    echo "Warning: Blueskyにログインしていません。投稿をスキップします。" >&2
    echo "ログイン方法: ssky login" >&2
    exit 0  # 非クリティカルなのでエラーにしない
fi

# Step 1: アブストラクト抽出
# ## アブストラクト セクションのコードフェンス内のテキストを抽出
awk '/## アブストラクト/{found=1; next} \
     found && /^```$/{count++; next} \
     found && count==1 && /^## /{exit} \
     found && count==1{print}' "$REPORT_FILE" > /tmp/abstract.txt

# 抽出内容チェック
if [ ! -s /tmp/abstract.txt ]; then
    echo "Error: アブストラクトが抽出できませんでした" >&2
    exit 1
fi

# Step 2: 投稿テキスト作成（アブストラクトにはすでにURLが含まれている）
cat /tmp/abstract.txt > /tmp/post.txt

# Step 3: Blueskyに投稿
# catでパイプ経由で渡す（標準入力として受け取る）
cat /tmp/post.txt | ssky post

# 投稿成功
echo "Bluesky投稿が完了しました" >&2

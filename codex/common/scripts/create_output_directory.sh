#!/bin/bash
# outputディレクトリを作成（存在しなければ）

set -e

if [ ! -d "./output" ]; then
    echo "outputディレクトリを作成します..."
    mkdir -p ./output

    if [ $? -eq 0 ]; then
        echo "outputディレクトリを作成しました"
    else
        echo "エラー: outputディレクトリの作成に失敗しました" >&2
        exit 1
    fi
else
    echo "outputディレクトリは既に存在します"
fi

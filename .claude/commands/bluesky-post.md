# Bluesky投稿コマンド

このコマンドは、生成されたレポートファイルからアブストラクトを抽出し、Blueskyに投稿します。

## 使い方

```
/bluesky-post <report_file_path>
```

**引数:**
- `report_file_path`: レポートファイルのパス（例: `output/日本成長戦略会議_第2回_20251224_report.md`）

**例:**
```
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

## 処理内容

### 1. 事前確認

#### sskyコマンドの存在確認

```bash
if ! command -v ssky &> /dev/null; then
    echo "❌ ssky command not found."
    echo "To install: pip install ssky"
    exit 1
fi
```

#### ログイン状態の確認

```bash
if ! ssky profile myself &> /dev/null; then
    echo "❌ Not logged in to Bluesky."
    echo "To login: ssky login"
    exit 1
fi
```

#### レポートファイルの存在確認

```bash
if [ ! -f "$REPORT_FILE" ]; then
    echo "❌ Report file not found: $REPORT_FILE"
    exit 1
fi
```

### 2. アブストラクトの抽出

report.mdからアブストラクトを抽出します。アブストラクトは`## アブストラクト`セクション内のコードフェンスで囲まれています。

```bash
# awkでコードフェンス内のテキストを抽出
ABSTRACT=$(awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE")

# 抽出結果を確認
if [ -z "$ABSTRACT" ]; then
    echo "❌ Failed to extract abstract from report file."
    exit 1
fi

echo "✓ Abstract extracted successfully (${#ABSTRACT} characters)"
```

### 3. Blueskyへの投稿

```bash
# 投稿実行（プロセス置換を使用）
# 注意: パイプ（|）ではなくプロセス置換（< <(...)）を使う
ssky post < <(awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE")

if [ $? -eq 0 ]; then
    echo "✅ Successfully posted to Bluesky!"
else
    echo "❌ Failed to post to Bluesky."
    exit 1
fi
```

### 4. 投稿結果の表示

```bash
# 最新の投稿を確認（オプション）
echo ""
echo "Latest post:"
ssky get --limit 1
```

## エラーハンドリング

このコマンドは以下のエラーを処理します：

1. **sskyコマンドが見つからない**: インストール方法を表示して終了
2. **Blueskyにログインしていない**: ログイン方法を表示して終了
3. **レポートファイルが存在しない**: エラーメッセージを表示して終了
4. **アブストラクト抽出失敗**: エラーメッセージを表示して終了
5. **投稿失敗**: エラーメッセージを表示して終了

## 文字数制限

Blueskyの投稿文字数制限は300文字（grapheme）ですが、アブストラクトは1,000字程度です。

**自動スレッド分割:**
- `ssky post`は長いテキストを自動的にスレッドに分割します
- 各ポストは前のポストに返信する形でスレッド化されます
- URL（最終行）は最後のポストに含まれます

**スレッド分割を無効化する場合:**
```bash
echo "$ABSTRACT" | ssky post --no-split
# ただし、300文字を超える部分は切り捨てられます
```

## ドライラン（テスト投稿）

実際に投稿せずに動作を確認したい場合：

```bash
echo "$ABSTRACT" | ssky post -d
```

これにより、投稿内容を確認できますが、実際には投稿されません。

## 完全な実装例

```bash
#!/bin/bash

# 引数チェック
if [ $# -eq 0 ]; then
    echo "Usage: /bluesky-post <report_file_path>"
    exit 1
fi

REPORT_FILE="$1"

# sskyコマンドの確認
if ! command -v ssky &> /dev/null; then
    echo "❌ ssky command not found."
    echo "To install: pip install ssky"
    exit 1
fi

# ログイン状態の確認
if ! ssky profile myself &> /dev/null; then
    echo "❌ Not logged in to Bluesky."
    echo "To login: ssky login"
    exit 1
fi

# レポートファイルの確認
if [ ! -f "$REPORT_FILE" ]; then
    echo "❌ Report file not found: $REPORT_FILE"
    exit 1
fi

# アブストラクトの抽出
echo "Extracting abstract from report..."
ABSTRACT=$(awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE")

if [ -z "$ABSTRACT" ]; then
    echo "❌ Failed to extract abstract from report file."
    exit 1
fi

echo "✓ Abstract extracted successfully (${#ABSTRACT} characters)"
echo ""

# Blueskyへの投稿
echo "Posting to Bluesky..."
if ssky post < <(awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "$REPORT_FILE"); then
    echo ""
    echo "✅ Successfully posted to Bluesky!"
else
    echo ""
    echo "❌ Failed to post to Bluesky."
    exit 1
fi
```

## 注意事項

- このコマンドは**非破壊的**です。投稿が失敗してもレポートファイルには影響しません
- 投稿は**公開**されます。機密情報が含まれていないことを確認してください
- Blueskyの利用規約とレート制限を遵守してください
- 同じ内容を繰り返し投稿するとスパムと見なされる可能性があります

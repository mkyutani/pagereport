---
name: file-writer
description: report.mdファイルの出力。pagereportスキルのステップ10で使用される内部サブエージェント
tools: Write, Bash
---

# file-writer

生成されたレポートをファイルに出力するサブエージェント。

**【重要】このサブエージェントの役割:**
- JSON形式で結果を出力したら、**自動的に完了して制御を返す**
- 出力後にユーザーの確認を待たない
- 呼び出し元（base_workflow.md）が自動的に次のステップ（Step 11）を開始する

**【重要】Bash toolの使用制限:**
- **Bash toolはシェルスクリプト実行のみに使用**
- ファイル読み取り: Bash cat/head/tail **禁止** → **Read tool** を使用
- ファイル検索: Bash find/ls **禁止** → **Glob tool** を使用
- コンテンツ検索: Bash grep/rg **禁止** → **Grep tool** を使用
- ファイル編集: Bash sed/awk **禁止** → **Edit tool** を使用
- ファイル書き込み: Bash echo/cat **禁止** → **Write tool** を使用
- ユーザーへの通信: Bash echo **禁止** → 直接テキスト出力を使用
- 許可される使用: `scripts/` 配下のシェルスクリプト実行、その他システムコマンド

## 目的

pagereport スキルのステップ10（ファイル出力）で使用されます。
アブストラクトと詳細レポートを統合し、`output/` ディレクトリにreport.mdファイルを生成します。

## 入力

**引数形式:**
```
<report_content_json> <output_filename>
```

**report_content_json:**
```json
{
  "metadata": {
    "meeting_name": "日本成長戦略会議",
    "meeting_date": "20251224",
    "meeting_date_original": "令和6年12月24日",
    "round_number": 2,
    "location": "官邸4階大会議室"
  },
  "abstract": {
    "text": "第2回日本成長戦略会議は、...",
    "url": "https://www.cas.go.jp/..."
  },
  "detailed_report": {
    "sections": [
      {"title": "基本情報", "content": "..."},
      {"title": "会議概要", "content": "..."},
      ...
    ]
  }
}
```

**output_filename:** 例: "日本成長戦略会議_第2回_20251224_report.md"

## 出力

### 成功時

```json
{
  "status": "success",
  "data": {
    "output_path": "./output/日本成長戦略会議_第2回_20251224_report.md",
    "file_size_bytes": 12345,
    "abstract_enclosed": true,
    "sections_count": 8,
    "absolute_path": "/home/user/work/pagereport/output/日本成長戦略会議_第2回_20251224_report.md"
  }
}
```

### エラー時

```json
{
  "status": "error",
  "error": {
    "code": "FILE_WRITE_FAILED",
    "message": "ファイルの書き込みに失敗しました",
    "level": "CRITICAL",
    "details": {
      "output_path": "./output/日本成長戦略会議_第2回_20251224_report.md",
      "error_message": "Permission denied"
    }
  }
}
```

## 処理フロー

### 1. 出力ディレクトリの確認と作成

```bash
# outputディレクトリが存在するか確認
if [ ! -d "./output" ]; then
    # 存在しなければ作成
    mkdir -p ./output
fi
```

### 2. レポート内容の構築

#### ファイル構成

```markdown
# {会議名}（第X回）

- **開催日時**: YYYY年MM月DD日（曜日）HH:MM～HH:MM
- **開催場所**: {場所}

## アブストラクト

```
{アブストラクト本文}
{元のURL}
```

{詳細レポートのセクション...}
```

**重要:** アブストラクトは必ずコードフェンス（\`\`\`）で囲む。
これによりBluesky投稿時に簡単に抽出できる。

### 3. ファイル書き込み

```python
# Writeツールでファイル作成
Write(
    file_path="./output/{output_filename}",
    content=report_content
)
```

### 4. 検証

```bash
# ファイルが正しく作成されたか確認
ls -l "./output/{output_filename}"

# ファイルサイズを取得
stat -f%z "./output/{output_filename}"  # macOS
stat -c%s "./output/{output_filename}"  # Linux
```

### 5. アブストラクト囲みの検証

```bash
# コードフェンスで囲まれているか確認
grep -A1 "## アブストラクト" "./output/{output_filename}" | grep "^\`\`\`$"
```

## エラーコード

### CRITICAL（処理中断）

- `DIRECTORY_CREATE_FAILED`: ディレクトリ作成失敗
  - 原因: 権限不足、ディスク容量不足
  - 対処: 権限確認、容量確認

- `FILE_WRITE_FAILED`: ファイル書き込み失敗
  - 原因: 権限不足、ディスク容量不足、ファイル名不正
  - 対処: 権限確認、容量確認、ファイル名確認

- `DISK_FULL`: ディスク容量不足
  - 原因: ディスクが満杯
  - 対処: 不要ファイルを削除

## 実装

### 外部スクリプトの使用

このサブエージェントは以下の外部スクリプトを使用します:

- `scripts/step10/validate_filename.py` - ファイル名の検証
- `scripts/step10/create_output_directory.sh` - 出力ディレクトリの作成

### 実装例

以下は実装の参考例です。実際には上記の外部スクリプトを使用してください。

### レポート内容の構築

```python
def build_report_content(report_data):
    """レポート内容を構築"""

    metadata = report_data['metadata']
    abstract = report_data['abstract']
    sections = report_data['detailed_report']['sections']

    # ヘッダー
    content = f"# {metadata['meeting_name']}（第{metadata['round_number']}回）\n\n"
    content += f"- **開催日時**: {metadata['meeting_date_original']}\n"
    content += f"- **開催場所**: {metadata['location']}\n\n"

    # アブストラクト（コードフェンスで囲む）
    content += "## アブストラクト\n\n"
    content += "```\n"
    content += abstract['text'] + "\n"
    content += abstract['url'] + "\n"
    content += "```\n\n"

    # 詳細セクション
    for section in sections:
        content += f"## {section['title']}\n\n"
        content += section['content'] + "\n\n"

    return content
```

### ファイル名の検証

```python
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
```

### ディレクトリ作成

```bash
#!/bin/bash
# outputディレクトリを作成（存在しなければ）

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
```

## ファイル名形式

### 標準形式

```
{会議名}_{回数}_{日付}_report.md
```

**例:**
```
日本成長戦略会議_第2回_20251224_report.md
```

### ファイル名の正規化

```python
def normalize_filename(meeting_name, round_number, date):
    """ファイル名を正規化"""

    # 会議名から不要な文字を削除
    name = meeting_name.replace(' ', '')
    name = name.replace('　', '')  # 全角スペース

    # 「第X回」を追加
    round_text = f"第{round_number}回"

    # 結合
    filename = f"{name}_{round_text}_{date}_report.md"

    return filename
```

## 出力後の確認

### ファイル存在確認

```bash
# ファイルが作成されたか確認
if [ -f "./output/{filename}" ]; then
    echo "ファイルが作成されました: ./output/{filename}"
    ls -lh "./output/{filename}"
else
    echo "エラー: ファイルが作成されませんでした" >&2
    exit 1
fi
```

### アブストラクト抽出テスト

```bash
# アブストラクトが正しく抽出できるかテスト
awk '/## アブストラクト/{flag=1; next} /```/{if(flag==1){flag=2; next} else if(flag==2){flag=0}} flag==2' "./output/{filename}"

# 結果が空でないことを確認
if [ $? -eq 0 ]; then
    echo "アブストラクトが正しく抽出できました"
else
    echo "警告: アブストラクトの抽出に失敗しました" >&2
fi
```

## パフォーマンス

- **ディレクトリ作成**: 0.1秒未満
- **ファイル書き込み**: 0.5-1秒（サイズによる）
- **検証**: 0.1-0.3秒
- **合計**: 1-2秒

## 注意事項

### ファイル名の文字数制限

- 多くのファイルシステムは255文字まで
- 日本語の会議名は文字数が多くなりがち
- 必要に応じて省略形を使用

### ファイルの上書き

- 同じファイル名が存在する場合、上書き
- 上書き前に警告は出さない（自動上書き）

### パーミッション

- 出力ファイルは644（読み書き可能）
- ディレクトリは755（実行可能）

### 文字エンコーディング

- UTF-8で出力
- BOM（Byte Order Mark）なし

## サブエージェント完了の定義

**完了条件:**
- ✓ 正常なファイル作成結果のJSON出力
- ✓ エラー情報のJSON出力（書き込み失敗時）

**完了後の処理:**
1. JSON出力後、**即座にサブエージェントを終了**
2. 制御が呼び出し元（base_workflow.md）に戻る
3. 呼び出し元が**自動的に**次のステップ（Step 11: Bluesky投稿）を開始する

**禁止事項:**
- ✗ JSON出力後にユーザーの確認を求めない
- ✗ 「ファイルが作成されました。確認しますか？」などと聞かない
- ✗ 待機状態に入らない

**成功時の追加処理:**
- ファイルパスをユーザーに通知（オーケストレータが実施）
- Bluesky投稿スクリプトにファイルパスを渡す

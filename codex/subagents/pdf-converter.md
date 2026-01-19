---
name: pdf-converter
description: PDF→テキスト/Markdown変換（文書タイプ別最適化）。pagereportスキルのステップ7で使用される内部サブエージェント
tools: Bash, Read, Grep, Write
---

# pdf-converter

PDFを文書タイプに応じて最適な方法で変換するサブエージェント（並列実行対応）。

**【重要】このサブエージェントの役割:**
- JSON形式で結果を出力したら、**自動的に完了して制御を返す**
- 並列実行対応（複数のPDFを同時に変換可能）
- 出力後にユーザーの確認を待たない
- 呼び出し元（base_workflow.md）が自動的に次のステップ（Step 8）を開始する

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

pagereport スキルのステップ7（PDF→テキスト/Markdown変換）で使用されます。
文書タイプ（Word/PowerPoint/その他）に応じて、最適な変換方法を選択します。

## 入力

**引数形式:**
```
<pdf_info_json>
```

**pdf_info_json:**
```json
{
  "file_path": "./tmp/shiryou1.pdf",
  "document_type": "powerpoint" | "word" | "other",
  "page_count": 45,
  "priority_score": 5,
  "title": "資料1-1"
}
```

## 出力

### 成功時

```json
{
  "status": "success",
  "data": {
    "input_path": "./tmp/shiryou1.pdf",
    "output_path": "./tmp/shiryou1.md",
    "output_format": "markdown" | "text",
    "conversion_method": "docling" | "pdftotext",
    "processing_details": {
      "full_text_path": "./tmp/shiryou1.txt",
      "full_markdown_path": "./tmp/shiryou1_full.md",
      "important_pages": [3, 4, 5, 6, 7, 10, 12, 15],
      "images_extracted": 23,
      "images_directory": "./tmp/shiryou1_images"
    },
    "file_size_bytes": 125000,
    "estimated_tokens": 15000,
    "page_count": 45
  }
}
```

### エラー時

```json
{
  "status": "error",
  "error": {
    "code": "PDFTOTEXT_FAILED",
    "message": "pdftotext変換に失敗しました",
    "level": "MAJOR",
    "details": {
      "pdf_path": "./tmp/shiryou1.pdf",
      "error_message": "Command not found",
      "fallback_available": true
    }
  }
}
```

## 処理フロー

### 戦略概要

```
全PDF共通:
├─ 7-1. pdftotextでテキスト化（高速スキャン、全PDF必須）
│
├─ PowerPoint由来PDF:
│  ├─ 7-2. スライドタイトルから重要ページ抽出
│  └─ 7-3. 重要ページのみdoclingでMarkdown化
│
└─ Word由来PDF/その他:
   └─ pdftotextの結果をそのまま使用（Step 8へ）
```

### 7-1. 全PDFのテキスト化（高速スキャン）

**全PDF（PowerPoint、Word、その他すべて）をpdftotextでテキスト化:**

```bash
# pdftotextが利用可能か確認
bash scripts/check_tool.sh pdftotext

if [ $? -eq 0 ]; then
    # pdftotextで変換
    bash scripts/convert_pdftotext.sh "./tmp/shiryou1.pdf" "./tmp/shiryou1.txt"
else
    # フォールバック: PyPDF2
    bash scripts/convert_pdftotext_fallback.sh "./tmp/shiryou1.pdf" "./tmp/shiryou1.txt"
fi
```

**処理時間の目安:**
- 小規模PDF (<10ページ): 5-10秒
- 中規模PDF (10-30ページ): 10-30秒
- 大規模PDF (30-50ページ): 30-60秒

**エラーハンドリング:**
- pdftotext失敗 → PyPDF2フォールバック
- PyPDF2も失敗 → Read toolで直接PDF読み取り

### 7-2. PowerPoint PDFの重要ページ抽出

**対象:** document_type == "powerpoint"

#### 処理手順

```bash
# 1. テキストファイルを読む
Read ./tmp/shiryou1.txt

# 2. ページ区切りを検出（\f = form feed）
# pdftotextは各ページを \f で区切る

# 3. 各ページの最初の1-2行をスライドタイトルとして抽出

# 4. スライドタイトルから重要度を判定
```

#### 重要ページの判定基準

**高優先度（必ず読む）:**
- 背景・現状認識
- 課題・問題点
- 方向性・戦略
- 具体的施策・取組
- 予算・スケジュール
- 目標・KPI
- 実績・成果

**低優先度（スキップ）:**
- 表紙（資料名のみ）
- 目次
- 参考資料
- 補足資料
- 用語集
- 組織図・名簿
- 免責事項・注記

#### 実装例

```python
def extract_important_pages(text):
    """テキストから重要ページを抽出"""

    pages = text.split('\f')  # ページ区切り
    important_pages = []

    high_priority_keywords = [
        '背景', '現状', '課題', '問題',
        '方向性', '戦略', 'ロードマップ',
        '施策', '取組', '予算', 'スケジュール',
        '目標', 'KPI', '実績', '成果'
    ]

    low_priority_keywords = [
        '目次', '参考', '補足', '用語集',
        '組織図', '名簿', '免責'
    ]

    for i, page in enumerate(pages, start=1):
        # 最初の2行を取得（スライドタイトル）
        lines = page.strip().split('\n')[:2]
        title = ' '.join(lines)

        # 低優先度キーワードをチェック
        if any(kw in title for kw in low_priority_keywords):
            continue

        # 高優先度キーワードをチェック
        if any(kw in title for kw in high_priority_keywords):
            important_pages.append(i)
        elif i <= 5:
            # 最初の5ページは重要
            important_pages.append(i)

    return important_pages
```

### 7-3. PowerPoint PDFの部分Markdown化

**ツール:** docling container

#### docling-serve containerの準備

```bash
# コンテナが起動しているか確認
docker ps | grep docling

# 起動していなければ起動
if [ $? -ne 0 ]; then
    docker start docling-server || docker run -d -p 5001:5001 --name docling-server quay.io/docling-project/docling-serve
fi
```

#### 非同期変換（推奨）

```bash
# 1. 非同期で変換タスクを投入
TASK_ID=$(bash scripts/docling_convert_async.sh "./tmp/shiryou1.pdf")

# 2. 完了を待機（ポーリング）
bash scripts/docling_poll_status.sh "$TASK_ID"

# 3. 結果を取得
bash scripts/docling_get_result.sh "$TASK_ID" "./tmp/shiryou1_full.md"

# 4. 画像を抽出してMarkdownから削除（重要！）
bash scripts/extract_images_from_md.sh "./tmp/shiryou1_full.md"

# 5. 重要ページのみ抽出
IMPORTANT_PAGES="3,4,5,6,7,10,12,15"
bash scripts/extract_important_pages.sh "./tmp/shiryou1_full.md" "./tmp/shiryou1.md" "$IMPORTANT_PAGES"
```

**処理時間の目安:**
- 小規模PDF (<10ページ): 1-2分
- 中規模PDF (10-30ページ): 3-5分
- 大規模PDF (30-50ページ): 5-8分

#### 画像抽出の重要性

**問題:** doclingは画像をbase64エンコードでMarkdownに埋め込むため、ファイルサイズが256KBを超える

**解決策:** `extract_images_from_md.sh` で画像を別ファイルに抽出し、Markdownから削除

```bash
# 画像を ./tmp/shiryou1_images/ に抽出
# Markdownから画像データを削除
# クリーンなMarkdownが ./tmp/shiryou1_full.md に残る
```

### Word由来PDF/その他の処理

**対象:** document_type == "word" | "other"

Word/その他のPDFは、7-1のpdftotext結果をそのまま使用:

```json
{
  "output_path": "./tmp/shiryou1.txt",
  "output_format": "text",
  "conversion_method": "pdftotext",
  "processing_details": {
    "full_text_path": "./tmp/shiryou1.txt"
  }
}
```

高速処理（数十秒）で完了。

### 処理方法の最終判断フロー

```python
def determine_conversion_strategy(pdf_info):
    """変換戦略を決定"""

    document_type = pdf_info['document_type']
    page_count = pdf_info['page_count']

    if document_type == 'powerpoint':
        # PowerPoint: pdftotext + docling
        return {
            "strategy": "ppt_with_docling",
            "steps": [
                "pdftotext_full",
                "extract_important_pages",
                "docling_partial"
            ]
        }
    elif document_type == 'word':
        # Word: pdftotextのみ
        return {
            "strategy": "word_pdftotext_only",
            "steps": ["pdftotext_full"]
        }
    else:
        # その他: pdftotextのみ
        return {
            "strategy": "other_pdftotext_only",
            "steps": ["pdftotext_full"]
        }
```

## エラーコード

### MAJOR（スキップして続行）

- `PDFTOTEXT_FAILED`: pdftotext変換失敗
  - 対処: PyPDF2フォールバック → Read tool

- `DOCLING_UNAVAILABLE`: doclingコンテナ起動失敗
  - 対処: pdftotextの結果のみ使用

- `DOCLING_TIMEOUT`: docling変換タイムアウト
  - 対処: pdftotextの結果のみ使用

### MINOR（警告のみ）

- `IMAGE_EXTRACTION_FAILED`: 画像抽出失敗
  - 対処: 画像付きMarkdownのまま続行

- `IMPORTANT_PAGE_EXTRACTION_FAILED`: 重要ページ抽出失敗
  - 対処: 全ページMarkdownを使用

## 実装例

### docling変換のエラーハンドリング

```bash
# 非同期変換
TASK_ID=$(bash scripts/docling_convert_async.sh "./tmp/shiryou1.pdf" 2>&1)

if [ $? -ne 0 ]; then
    echo "docling変換の開始に失敗しました" >&2
    # フォールバック: pdftotextの結果を使用
    OUTPUT_PATH="./tmp/shiryou1.txt"
    CONVERSION_METHOD="pdftotext"
else
    # ポーリング（最大10分）
    bash scripts/docling_poll_status.sh "$TASK_ID"

    if [ $? -eq 0 ]; then
        # 結果取得
        bash scripts/docling_get_result.sh "$TASK_ID" "./tmp/shiryou1_full.md"

        # 画像抽出
        bash scripts/extract_images_from_md.sh "./tmp/shiryou1_full.md"

        # 重要ページ抽出
        bash scripts/extract_important_pages.sh "./tmp/shiryou1_full.md" "./tmp/shiryou1.md" "$IMPORTANT_PAGES"

        OUTPUT_PATH="./tmp/shiryou1.md"
        CONVERSION_METHOD="docling"
    else
        echo "docling変換がタイムアウトしました" >&2
        # フォールバック: pdftotextの結果を使用
        OUTPUT_PATH="./tmp/shiryou1.txt"
        CONVERSION_METHOD="pdftotext"
    fi
fi
```

### 並列実行のサポート

複数のPDFを並列変換する場合、オーケストレータが複数のTaskツールを同時に呼び出す:

```
Task 1: pdf-converter {"file_path": "./tmp/shiryou1.pdf", ...}
Task 2: pdf-converter {"file_path": "./tmp/shiryou2.pdf", ...}
Task 3: pdf-converter {"file_path": "./tmp/shiryou3.pdf", ...}
```

各サブエージェントは独立して動作:
- doclingの非同期変換を並列投入
- 各自のTASK_IDで管理
- 完了を待機
- 結果を返す

**処理時間の比較:**
- 順次実行: 5分 + 5分 + 5分 = 15分
- 並列実行: max(5分, 5分, 5分) + オーバーヘッド = 6-7分

## トークン最適化

### PowerPoint PDFの最適化

- 全50ページ中、重要ページ10-20ページに絞る
- トークン消費を60-80%削減

### Word PDFの最適化

- pdftotext出力は軽量（Markdown変換不要）
- 後続のmaterial-analyzerで部分読み取り

## パフォーマンス

| 文書タイプ | 処理内容 | 時間 |
|-----------|---------|------|
| Word PDF (30ページ) | pdftotext のみ | 30秒 |
| PowerPoint PDF (50ページ) | pdftotext + 重要ページ抽出 + docling部分変換 | 5-8分 |
| その他 PDF (10ページ) | pdftotext のみ | 10秒 |

**並列処理の効果:**
- 3つのPowerPoint PDF: 順次15分 → 並列7分（50%短縮）

## 注意事項

### doclingの制限

- 同期変換は120秒でタイムアウト（小PDFのみ使用可）
- 非同期変換を推奨（>10ページ）

### ファイルサイズ

- 画像抽出前のMarkdown: 数MB（Read tool不可）
- 画像抽出後のMarkdown: 通常100KB未満（Read tool可）

### 一時ファイルの管理

- `./tmp/` に多数のファイルが生成される
- 処理完了後も削除しない（後続ステップで使用）

## サブエージェント完了の定義

**完了条件:**
- ✓ 正常な変換結果のJSON出力
- ✓ エラー時もフォールバックで可能な限り結果を返す

**完了後の処理:**
1. JSON出力後、**即座にサブエージェントを終了**
2. 制御が呼び出し元（base_workflow.md）に戻る
3. 呼び出し元が**自動的に**次のPDF変換または次のステップ（Step 8: material-analyzer）を開始する

**禁止事項:**
- ✗ JSON出力後にユーザーの確認を求めない
- ✗ 「変換が完了しました。次に進みますか？」などと聞かない
- ✗ 待機状態に入らない

**並列実行時:**
- 各サブエージェントは独立して完了
- オーケストレータが全完了を検出
- 自動的に次のステップに進む

## Codex CLI 実装

文書タイプに応じて変換する。基本は `convert_pdftotext.sh`、PowerPointは docling を使用する。
```
bash codex/common/scripts/convert_pdftotext.sh "<pdf>" "./tmp/<name>.txt"
bash codex/common/scripts/convert_pdftotext_fallback.sh "<pdf>" "./tmp/<name>.txt"
bash codex/common/scripts/docling_convert_async.sh "<pdf>" "./tmp/<name>.md"
bash codex/common/scripts/docling_poll_status.sh "<task_id>"
bash codex/common/scripts/docling_get_result.sh "<task_id>" "./tmp/<name>.md"
```
結果を `./tmp/step7.json` にまとめる。

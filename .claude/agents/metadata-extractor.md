---
name: metadata-extractor
description: HTMLまたはPDFから会議名、日付、回数、場所を自動抽出。pagereportスキルのステップ2で使用される内部サブエージェント
tools: Read, Grep, Bash
---

# metadata-extractor

HTMLまたはPDFから会議のメタデータ（会議名、日付、回数、場所）を自動抽出するサブエージェント。

**【重要】このサブエージェントの役割:**
- JSON形式で結果を出力したら、**自動的に完了して制御を返す**
- 必須メタデータが取得できない場合、エラーを返す（ユーザー入力が必要）
- 出力後にユーザーの確認を待たない
- 呼び出し元（base_workflow.md）が自動的に次のステップ（Step 2.5）を開始する

**【重要】Bash toolの使用制限:**
- **Bash toolはシェルスクリプト実行のみに使用**
- ファイル読み取り: Bash cat/head/tail **禁止** → **Read tool** を使用
- ファイル検索: Bash find/ls **禁止** → **Glob tool** を使用
- コンテンツ検索: Bash grep/rg **禁止** → **Grep tool** を使用
- ファイル編集: Bash sed/awk **禁止** → **Edit tool** を使用
- ファイル書き込み: Bash echo/cat **禁止** → **Write tool** を使用
- ユーザーへの通信: Bash echo **禁止** → 直接テキスト出力を使用
- 許可される使用: `.claude/skills/common/scripts/` 配下のシェルスクリプト実行、その他システムコマンド

## 目的

pagereport スキルのステップ2（メタデータ自動抽出）で使用されます。
会議名、日付（YYYYMMDD形式）、回数、場所を抽出し、ファイル名生成に使用します。

## 入力

**引数形式:**
```
<content_json>
```

**content_json:**
```json
{
  "html_content": "HTML内容（content-acquirerの出力）",
  "page_title": "第2回日本成長戦略会議",
  "pdf_links": [
    {
      "text": "議事次第",
      "url": "https://...",
      "estimated_category": "agenda"
    }
  ],
  "original_url": "https://..."
}
```

## 出力

### 成功時

```json
{
  "status": "success",
  "data": {
    "meeting_name": "日本成長戦略会議",
    "meeting_date": "20251224",
    "meeting_date_original": "令和6年12月24日",
    "round_number": 2,
    "round_text": "第2回",
    "location": "官邸4階大会議室",
    "time": "10:00-11:30",
    "confidence": {
      "meeting_name": "high",
      "date": "high",
      "round": "high",
      "location": "medium",
      "time": "low"
    },
    "extraction_source": {
      "meeting_name": "page_title",
      "date": "html_body",
      "round": "page_title",
      "location": "html_body",
      "time": "not_found"
    }
  }
}
```

### エラー時（必須メタデータ欠如）

```json
{
  "status": "error",
  "error": {
    "code": "METADATA_MISSING",
    "message": "必須メタデータが取得できませんでした。ユーザーに入力を求めてください。",
    "level": "CRITICAL",
    "details": {
      "missing_fields": ["meeting_name", "meeting_date"],
      "partial_data": {
        "round_number": 2,
        "location": null
      },
      "requires_user_input": true
    }
  }
}
```

## 処理フロー

### 1. 会議名の抽出

**優先順位:**

1. **ページタイトル（h1）から抽出**
   ```
   入力: "第2回日本成長戦略会議"
   処理: 「第X回」を削除
   出力: "日本成長戦略会議"
   ```

2. **HTML本文から抽出**
   ```
   パターン: "会議名:"、"会議の名称:"など
   ```

3. **議事次第PDFから抽出**
   ```
   PDFの1ページ目から会議名を検索
   ```

**正規化処理:**
- 前後の空白を削除
- 「第X回」を削除
- 「（第X回）」を削除
- 全角/半角の統一

**信頼度判定:**
- `high`: ページタイトルまたはPDF1ページ目から取得
- `medium`: HTML本文から取得
- `low`: 推測による取得

### 2. 日付の抽出と変換

**日付パターン検出:**

```regex
# 令和表記
令和(\d+)年(\d+)月(\d+)日

# 平成表記（参考）
平成(\d+)年(\d+)月(\d+)日

# 西暦表記
(\d{4})年(\d+)月(\d+)日
```

**元号→西暦変換:**

```python
def convert_to_western_year(era, year, month, day):
    """
    元号を西暦に変換

    令和: 2019年5月1日開始
    令和X年 = 2018 + X年
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

# 例: 令和6年12月24日
# → 2018 + 6 = 2024年
# → 20241224
```

**抽出ソース:**
1. HTML本文（優先度: 高）
2. 議事次第PDF（優先度: 中）
3. ページタイトル（優先度: 低）

### 3. 回数の抽出

**パターン:**
```regex
第(\d+)回
第（\d+）回
```

**抽出ソース:**
1. ページタイトル（優先度: 高）
2. HTML本文（優先度: 中）
3. URL（例: `dai2/`）（優先度: 低）

**例:**
```
入力: "第2回日本成長戦略会議"
出力: round_number=2, round_text="第2回"
```

### 4. 開催場所の抽出

**パターン:**
```regex
場所[:：]\s*(.+)
開催場所[:：]\s*(.+)
会場[:：]\s*(.+)
```

**抽出ソース:**
1. HTML本文（優先度: 高）
2. 議事次第PDF（優先度: 中）

**例:**
```
入力: "場所: 官邸4階大会議室"
出力: location="官邸4階大会議室"
```

### 5. 開催時刻の抽出

**パターン:**
```regex
(\d{1,2})[:：](\d{2})\s*[~～〜-]\s*(\d{1,2})[:：](\d{2})
時間[:：]\s*(.+)
```

**例:**
```
入力: "10:00～11:30"
出力: time="10:00-11:30"
```

### 6. 信頼度と抽出ソースの記録

各メタデータについて:
- `confidence`: high / medium / low
- `extraction_source`: どこから抽出したか

## エラーコード

### CRITICAL（処理中断、ユーザー入力が必要）

- `METADATA_MISSING`: 必須メタデータ（会議名、日付、回数）が取得できない
  - 対処: ユーザーに手動入力を求める

- `DATE_PARSE_FAILED`: 日付のパースに失敗
  - 原因: 想定外の日付フォーマット
  - 対処: ユーザーに手動入力を求める

### MAJOR（スキップして続行）

- `ROUND_NUMBER_NOT_FOUND`: 回数が取得できない
  - 対処: デフォルト値（1）を使用、警告を出す

### MINOR（警告のみ）

- `LOCATION_NOT_FOUND`: 開催場所が取得できない
  - 対処: nullを返す、レポートには「不明」と記載

- `TIME_NOT_FOUND`: 開催時刻が取得できない
  - 対処: nullを返す

## 実装

### 外部スクリプトの使用

このサブエージェントは以下の外部スクリプトを使用します:

- `.claude/skills/common/scripts/step2/convert_era_to_western.py` - 元号→西暦変換
- `.claude/skills/common/scripts/step2/normalize_meeting_name.py` - 会議名の正規化

### 実装例

以下は実装の参考例です。実際には上記の外部スクリプトを使用してください。

### 元号→西暦変換

```python
import re

def extract_and_convert_date(html_content):
    """日付を抽出して西暦YYYYMMDD形式に変換"""

    # 令和パターン
    pattern = r'令和(\d+)年(\d+)月(\d+)日'
    match = re.search(pattern, html_content)

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
            "extraction_source": "html_body"
        }

    return None
```

### 会議名の正規化

```python
def normalize_meeting_name(raw_name):
    """会議名から不要な文字列を削除"""

    # 「第X回」を削除
    name = re.sub(r'第\d+回\s*', '', raw_name)
    name = re.sub(r'第（\d+）回\s*', '', name)

    # 「（第X回）」を削除
    name = re.sub(r'[（(]第\d+回[）)]\s*', '', name)

    # 前後の空白を削除
    name = name.strip()

    return name

# 例:
# "第2回日本成長戦略会議" → "日本成長戦略会議"
# "日本成長戦略会議（第2回）" → "日本成長戦略会議"
```

## 議事次第PDFからの抽出

議事次第PDFが存在する場合、そこから追加のメタデータを抽出:

```bash
# 議事次第PDFをテキスト化（最初の2ページのみ）
pdftotext -f 1 -l 2 ./tmp/shidai.pdf ./tmp/shidai_meta.txt

# テキストから日付、場所などを抽出
grep -E "令和.*年.*月.*日|場所:" ./tmp/shidai_meta.txt
```

## ユーザー入力が必要な場合の処理

必須メタデータが取得できない場合、オーケストレータは:

1. エラーJSONを受け取る
2. `requires_user_input: true` を確認
3. AskUserQuestionツールでユーザーに入力を求める
4. ユーザー入力を受け取ったら、メタデータを補完して次のステップへ

## パフォーマンス

- **HTML解析**: 0.5-1秒
- **パターンマッチング**: 0.1-0.3秒
- **PDF読み取り（オプション）**: 1-2秒
- **合計**: 1-3秒

## 注意事項

### 元号の更新

新しい元号が始まった場合、変換ロジックを更新する必要があります:
- 令和: 2019年5月1日開始（令和X年 = 2018 + X）
- 次の元号: 開始年に応じて追加

### 曖昧な日付表記

- 「12月中旬」「年末」などの曖昧な表記の場合、エラーを返す
- ユーザーに正確な日付を入力してもらう

### 回数が0の場合

「第0回」は存在しないため、最小値は1とする。
取得できない場合はデフォルト値1を使用。

## サブエージェント完了の定義

**完了条件:**
- ✓ 正常な抽出結果のJSON出力
- ✓ エラー情報のJSON出力（ユーザー入力が必要な場合）

**完了後の処理:**
1. JSON出力後、**即座にサブエージェントを終了**
2. 制御が呼び出し元（base_workflow.md）に戻る
3. エラーの場合、オーケストレータがユーザーに入力を求める
4. 成功の場合、オーケストレータが**自動的に**次のステップ（Step 2.5: page-type-detector）を開始する

**禁止事項:**
- ✗ JSON出力後にユーザーの確認を求めない
- ✗ メタデータが足りない場合でも、このサブエージェント内でユーザーに質問しない
- ✗ 待機状態に入らない

---
name: document-type-classifier
description: PDF文書の種類を自動判定（Word/PowerPoint/その他）。pagereportスキルのステップ6で使用される内部サブエージェント
allowed-tools:
  - Bash(pdftotext:*)
  - Bash(pdfinfo:*)
  - Read(path:/tmp/*)
  - Write(path:/tmp/*)
auto-execute: true
---

# document-type-classifier

PDF文書の種類を自動判定するサブエージェント。
PDFの最初の5ページを分析し、Word/PowerPoint/議事次第/名簿/ニュース/調査/その他のカテゴリに分類します。

## 用途

pagereport スキルのステップ6（文書タイプ判定）で使用されます。
判定結果に基づいて、ステップ7で最適な変換方法（docling/pdftotext）を選択します。

## 引数

```
<pdf_file_path>
```

- `pdf_file_path`: 判定対象のPDFファイルの絶対パス（例: `/tmp/shiryou1.pdf`）

## 出力

JSON形式で標準出力に結果を出力します:

```json
{
  "file_path": "/tmp/shiryou1.pdf",
  "document_type": "powerpoint",
  "confidence": "high",
  "reason": "スライドタイトル、箇条書き記号（●、・）が多数、体言止めの頻度が高い",
  "key_indicators": [
    "箇条書き記号の頻度: 高",
    "1ページあたりのトピック数: 1-2",
    "体言止めの頻度: 高",
    "完全な文章構造: 低"
  ],
  "page_count": 45
}
```

### フィールド説明

- `file_path`: 入力ファイルパス
- `document_type`: 判定された文書タイプ
  - `word`: Word由来（詳細レポート、完全な文章構造）
  - `powerpoint`: PowerPoint由来（プレゼン資料、箇条書き中心）
  - `agenda`: 議事次第（会議スケジュール）
  - `participants`: 参加者名簿（委員リスト）
  - `news`: ニュース・プレスリリース
  - `survey`: 調査・アンケート結果
  - `other`: その他
- `confidence`: 判定の信頼度（`high` / `medium` / `low`）
- `reason`: 判定理由の簡潔な説明
- `key_indicators`: 判定の根拠となった具体的な指標（配列）
- `page_count`: PDFの総ページ数（取得可能な場合）

## 処理フロー

1. **PDF読み取り**: pdftotextで最初の5ページだけを抽出
   ```bash
   # 最初の5ページだけをテキスト抽出（高速・確実）
   pdftotext -f 1 -l 5 /tmp/document.pdf /tmp/document_first5.txt

   # 抽出されたテキストファイルを読む（軽量なので "PDF too large" エラーにならない）
   Read /tmp/document_first5.txt
   ```
   - `-f 1`: 開始ページ（1ページ目から）
   - `-l 5`: 終了ページ（5ページ目まで）
   - 5ページ未満のPDFでも自動的に全ページを抽出
   - **大きなPDFでも確実に5ページだけ抽出**するため "PDF too large" エラーを回避

2. **文章構造分析**: 以下の観点で分析
   - 完全な文（主語・述語あり）の頻度
   - 箇条書き記号（●、・、○、①など）の頻度
   - 体言止め（名詞で終わる）の頻度
   - 1ページあたりのトピック数
   - 段落の有無と長さ
   - 助詞（は、が、を、に、で）の使用頻度
   - です/ます調、または だ/である調の使用

3. **特徴抽出**: 文書タイプ別の特徴を検出

4. **判定と出力**: 最も可能性の高いタイプを判定し、JSON形式で出力

## 判定基準

### Word文書の特徴

- ✓ 完全な文（主語・述語あり）
- ✓ 段落構造（複数文が連続）
- ✓ 論理的展開（序論→本論→結論）
- ✓ 日本語助詞の頻繁な使用（は、が、を、に、で）
- ✓ です/ます調、または だ/である調
- ✓ 引用表現（「〜によれば」「〜によると」）
- ✓ 詳細な説明文

### PowerPoint文書の特徴

- ✓ スライドタイトル（各ページ1-2トピック）
- ✓ 箇条書き記号（●、・、○、①、②）の多用
- ✓ キーワード主体、短いフレーズ
- ✓ 体言止め（「〜について」「〜に関して」で終わる）
- ✓ 参照表現（「下図のとおり」「次の表」）
- ✓ 図表中心のレイアウト
- ✓ 階層構造（大項目→小項目）

### 議事次第の特徴

- ✓ 「議事次第」「次第」のタイトル
- ✓ 時刻と議題のリスト（「13:00 開会」など）
- ✓ 出席者リスト
- ✓ 配布資料一覧

### 参加者名簿の特徴

- ✓ 「委員名簿」「出席者名簿」のタイトル
- ✓ 人名と所属・役職のリスト
- ✓ 表形式のレイアウト

### ニュース・プレスリリースの特徴

- ✓ 「プレスリリース」「報道発表」のタイトル
- ✓ 日付と発信元が冒頭に記載
- ✓ 5W1H形式の記述

### 調査・アンケートの特徴

- ✓ 「調査結果」「アンケート」のタイトル
- ✓ 質問項目と回答データ
- ✓ グラフ・表が大部分を占める
- ✓ 数値データ・統計情報が中心

## エラーハンドリング

1. **ファイルが存在しない**:
   ```json
   {
     "file_path": "/tmp/nonexistent.pdf",
     "error": "file_not_found",
     "message": "指定されたファイルが見つかりません"
   }
   ```

2. **PDFの読み取りに失敗**:
   ```json
   {
     "file_path": "/tmp/corrupted.pdf",
     "error": "read_failed",
     "message": "PDFの読み取りに失敗しました: [エラー詳細]"
   }
   ```

3. **判定不能**:
   ```json
   {
     "file_path": "/tmp/unknown.pdf",
     "document_type": "other",
     "confidence": "low",
     "reason": "明確な文書タイプの特徴が検出できませんでした",
     "key_indicators": []
   }
   ```

## 使用例

```bash
# 単一PDFの判定
/document-type-classifier "/tmp/shiryou1.pdf"

# 出力例（JSON）
{
  "file_path": "/tmp/shiryou1.pdf",
  "document_type": "powerpoint",
  "confidence": "high",
  "reason": "スライドタイトル、箇条書き記号が多数、体言止めの頻度が高い",
  "key_indicators": [
    "箇条書き記号の頻度: 高（50箇所以上）",
    "1ページあたりのトピック数: 1-2",
    "体言止めの頻度: 高（80%以上）",
    "完全な文章構造: 低（20%未満）"
  ],
  "page_count": 45
}
```

## 並列実行

このサブエージェントは並列実行に対応しています。
複数のPDFを同時に判定することで、全体の処理時間を短縮できます。

```bash
# 複数PDFの並列判定（pagereportスキル内で自動的に実行）
# Task tool with multiple invocations
```

## 注意事項

- このサブエージェントは、文書の**形式**を判定するものであり、**内容**の評価は行いません
- 判定結果は次のステップ（PDF→Markdown変換）の処理方法選択にのみ使用されます
- 信頼度が `low` の場合でも、best-effort で最も可能性の高いタイプを返します
- 短いPDF（1-2ページ）の場合、判定精度が低下する可能性があります

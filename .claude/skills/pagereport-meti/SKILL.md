---
name: pagereport-meti
description: 経済産業省会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www.meti.go.jp)
  - Bash(curl:*)
  - Bash(python3:*)
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Bash(docker:*)
  - Read
  - Write
---

# 経済産業省 会議ページサマリー作成スキル

## 対象ドメイン
- www.meti.go.jp

## 府省庁固有の情報

### 実行例
```
/pagereport-meti "https://www.meti.go.jp/..."
```

### 重要：User-Agent要件

**METIのサイトはUser-Agentベースのフィルタリングを実装しており、curlのデフォルトUser-Agent（curl/x.x.x）からのリクエストを拒否します。**

**HTMLページ取得、PDFダウンロードなど、meti.go.jpへのすべてのcurlリクエストで必ずブラウザのUser-Agentを指定してください：**

```bash
# HTMLページ取得時
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  "https://www.meti.go.jp/committee/..."

# PDFダウンロード時
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  -o /tmp/file.pdf "https://www.meti.go.jp/policy/..."
```

**重要**: WebFetchツールもmeti.go.jpではUser-Agent制限により失敗する可能性があります。HTMLページ取得にはcurlの使用を推奨します。

User-Agentを指定しない場合、リクエストがタイムアウトまたは失敗します。

### HTML構造のヒント
（将来的に追加予定 - 会議名セレクタ、日付フォーマットなど）

### 会議ページの読み方
（将来的に追加予定 - 会議一覧ページのURL、会議リンクの抽出方法など）

---

## 実行指示

このスキルが呼び出されたら、以下の11ステップを**自動的に**実行してください。**人間の確認を求めず**、各ステップが完了したら即座に次のステップに進んでください。

詳細な処理ルールは[共通ベースワークフロー](../common/base_workflow.md)を参照してください。

### Step 1: HTMLページ取得

- curlでHTMLを取得（**User-Agent必須**）
- メタデータ抽出: 会議名、日付（YYYYMMDD変換）、回数

### Step 2-5: 資料の選択とダウンロード

- HTMLからPDFリンクを抽出し、優先度スコアリング（1-5点）
- スコア4以上のPDFをcurlでダウンロード（**User-Agent必須**）

### Step 6: 文書タイプ判定（自動実行、確認不要）

- ダウンロードした各PDFについて`document-type-classifier`スキルを**並列実行**
- **判定結果を内部で記録し、即座にStep 7に進む**
- 人間への確認や出力は不要

### Step 7: PDF→テキスト変換（自動実行、確認不要）

- 全PDFをpdftotextでテキスト化
- PowerPoint PDFの場合: 重要ページを抽出（30ページ程度）
- Word PDFの場合: 全文テキストを使用
- **変換完了後、即座にStep 8に進む**
- 人間への確認や出力は不要

### Step 8: 資料分析（自動実行、確認不要）

- 変換済みファイルについて`material-analyzer`スキルを**並列実行**
- **分析結果を内部で記録し、即座にStep 9に進む**
- 人間への確認や出力は不要

### Step 9-10: レポート生成（自動実行、確認不要）

- 1,000字以内のアブストラクト生成（論文形式、5要素構成）
- `mkdir -p ./output`を実行
- `output/{会議名}_{回数}_{日付}_report.md`をWriteツールで作成
- **ファイル作成時も人間への確認不要、即座に実行**

### Step 11: Bluesky投稿（自動実行、確認不要）

- sskyでアブストラクトを投稿（ログインしていない場合はスキップ）
- **投稿完了後、最終結果のみ報告**

**重要**:
- 各ステップは自動的に実行し、人間の確認を**待たずに**次に進むこと
- 中間結果は出力して進捗を見せるが、確認を待たない
- 判定結果や変換結果を出力したら、即座に次のステップの処理を開始すること

---

## 実践例

### 第3回 キャッシュレス推進検討会

**URL**: https://www.meti.go.jp/shingikai/mono_info_service/cashless_promotion/003.html

**処理フロー:**

1. **HTML取得** (User-Agent必須):
   ```bash
   curl -A "Mozilla/5.0 ..." "https://www.meti.go.jp/shingikai/mono_info_service/cashless_promotion/003.html"
   ```

2. **メタデータ抽出**:
   - 会議名: キャッシュレス推進検討会
   - 日付: 令和7年12月19日 → 20251219
   - 回数: 第3回

3. **PDF特定と優先度スコアリング**:
   - 議事次第 (003_01_00.pdf): スコア 2
   - 議事要旨 (003_gijiyoshi.pdf): スコア 4
   - 概要版 (003_03_00.pdf, 32ページ): スコア 5
   - とりまとめ本編 (003_04_00.pdf, 47ページ): スコア 5

4. **PDF Markdown化** (docling非同期処理):
   - 4件のPDFを並行して非同期変換投入
   - 処理時間: 約10分
   - 結果:
     * 議事要旨: 67行
     * 概要版: 648行 (ファイルサイズ756.5KB、base64画像含む)
     * 本編: 989行

5. **大規模Markdownの処理**:
   - 概要版と本編はRead toolの256KB制限を超える
   - Grepで見出し抽出して構造把握:
     ```bash
     grep "^#{1,3}\s+" /tmp/003_03_00.md
     ```
   - 主要セクション: 社会的意義、指標見直し、目標設定、課題と取組、大阪万博事例

6. **要約生成**:
   - サマリー: 1,000字のアブストラクト + 資料リスト
   - 詳細レポート: 約10,000字、8セクション構成

**成果物**:
- `output/キャッシュレス推進検討会_20251219_第3回_summary.txt`
- `output/キャッシュレス推進検討会_20251219_第3回_detail.md`

**重要な学び**:
- 中～大規模PDF（>10ページ）は必ず非同期処理を使用
- 複数PDFは並行投入で効率化
- Markdown化後もbase64画像でファイルサイズ大→Grepで構造把握
- User-Agent指定は全curlリクエストで必須

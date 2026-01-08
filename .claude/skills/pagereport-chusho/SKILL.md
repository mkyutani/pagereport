---
name: pagereport-chusho
description: 中小企業庁会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www.chusho.meti.go.jp)
  - Bash(curl:*)
  - Bash(python3:*)
  - Bash(pdftotext:*)
  - Bash(docker:*)
  - Bash(awk:*)
  - Bash(ssky:*)
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Bash(grep:*)
  - Read(path:/tmp/*)
  - Read(path:./output/*)
  - Write(path:/tmp/*)
  - Write(path:./output/*)
  - Edit(path:/tmp/*)
  - Edit(path:./output/*)
  - Skill(document-type-classifier)
  - Skill(material-analyzer)
---

# 中小企業庁 会議ページサマリー作成スキル

## 対象ドメイン
- www.chusho.meti.go.jp

## 府省庁固有の情報

### 実行例
```
/pagereport-chusho "https://www.chusho.meti.go.jp/..."
```

### 重要：User-Agent要件

**中小企業庁のサイトはMETIと同様にUser-Agentベースのフィルタリングを実装している可能性があり、curlのデフォルトUser-Agent（curl/x.x.x）からのリクエストを拒否する場合があります。**

**HTMLページ取得、PDFダウンロードなど、chusho.meti.go.jpへのすべてのcurlリクエストで必ずブラウザのUser-Agentを指定してください：**

```bash
# HTMLページ取得時
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  "https://www.chusho.meti.go.jp/..."

# PDFダウンロード時
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  -o /tmp/file.pdf "https://www.chusho.meti.go.jp/..."
```

**重要**: WebFetchツールもchusho.meti.go.jpではUser-Agent制限により失敗する可能性があります。HTMLページ取得にはcurlの使用を推奨します。

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

（今後、中小企業庁の会議ページを処理した際に実例を追加予定）

---
name: pagereport-cao
description: 総務省会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www8.cao.go.jp)
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

# 総務省 会議ページサマリー作成スキル

## 対象ドメイン
- www8.cao.go.jp

## 府省庁固有の情報

### 実行例
```
/pagereport-cao "https://www8.cao.go.jp/..."
```

### HTML構造のヒント
（将来的に追加予定 - 会議名セレクタ、日付フォーマットなど）

### 会議ページの読み方
（将来的に追加予定 - 会議一覧ページのURL、会議リンクの抽出方法など）

---

## 実行指示

このスキルが呼び出されたら、以下の11ステップを**自動的に**実行してください。**人間の確認を求めず**、各ステップが完了したら即座に次のステップに進んでください。

詳細な処理ルールは[共通ベースワークフロー](../common/base_workflow.md)を参照してください。

### Step 1-5: HTML取得と資料ダウンロード
- WebFetchでHTMLを取得
- メタデータ抽出、PDFリンク抽出、優先度スコアリング、ダウンロード

### Step 6: 文書タイプ判定（自動実行、確認不要）
- 各PDFについて`document-type-classifier`スキルを**並列実行**
- **判定結果を内部で記録し、即座にStep 7に進む**（人間への確認不要）

### Step 7: PDF→テキスト変換（自動実行、確認不要）
- 全PDFをpdftotextでテキスト化、重要ページ抽出
- **変換完了後、即座にStep 8に進む**（人間への確認不要）

### Step 8: 資料分析（自動実行、確認不要）
- `material-analyzer`スキルを**並列実行**
- **分析結果を内部で記録し、即座にStep 9に進む**（人間への確認不要）

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

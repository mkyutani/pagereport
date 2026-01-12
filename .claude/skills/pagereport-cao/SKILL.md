---
name: pagereport-cao
description: 総務省会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www8.cao.go.jp)
  - Bash(bash:*)
  - Bash(sh:*)
  - Bash(curl:*)
  - Bash(python3:*)
  - Bash(pdftotext:*)
  - Bash(docker:*)
  - Bash(awk:*)
  - Bash(ssky:*)
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Bash(grep:*)
  - Bash(wc:*)
  - Bash(cat:*)
  - Bash(head:*)
  - Bash(tail:*)
  - Bash(which:*)
  - Bash(command:*)
  - Bash(sleep:*)
  - Bash(chmod:*)
  - Bash(wget:*)
  - Read(path:/tmp/*)
  - Read(path:./output/*)
  - Write(path:/tmp/*)
  - Write(path:./output/*)
  - Edit(path:/tmp/*)
  - Edit(path:./output/*)
auto-execute: true
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
- メタデータ抽出: 会議名、日付（YYYYMMDD変換）、回数
- HTMLからPDFリンクを抽出し、優先度スコアリング（1-5点）
- スコア4以上のPDFをスクリプトでダウンロード：
  ```bash
  bash .claude/skills/common/scripts/download_pdf.sh "<URL>" "/tmp/<filename>"
  ```
- **完了したら即座にStep 6へ**

### Step 6: 文書タイプ判定（完全自動、確認不要）
- 各PDFについて`document-type-classifier`スキルを**並列実行**
- **サブエージェントがJSON出力 = 完了**
- **判定結果を内部で記録し、ユーザー確認なしで即座にStep 7に進む**

### Step 7: PDF→テキスト変換（完全自動、確認不要）
- 全PDFをpdftotextでテキスト化
- PowerPoint PDFの場合: 重要ページを抽出（30ページ程度）
- Word PDFの場合: 全文テキストを使用
- **変換完了したら、ユーザー確認なしで即座にStep 8に進む**

### Step 8: 資料分析（完全自動、確認不要）
- `material-analyzer`スキルを**並列実行**
- **サブエージェントがJSON出力 = 完了**
- **分析結果を内部で記録し、ユーザー確認なしで即座にStep 9に進む**

### Step 9-10: レポート生成（完全自動、確認不要）
- 1,000字以内のアブストラクト生成（論文形式、5要素構成）
- `mkdir -p ./output`を実行
- `output/{会議名}_{回数}_{日付}_report.md`をWriteツールで作成
- **ファイル作成時もユーザー確認不要、即座に実行してStep 11へ**

### Step 11: Bluesky投稿（完全自動、確認不要）
- **【必須】専用スクリプト `bash .claude/skills/bluesky-post/post.sh` を使用**
- アブストラクトを投稿（ログインしていない場合はスキップ）
- **投稿完了後、最終結果のみ報告**
- **禁止**: awkやssky postを直接呼び出さない

---
name: pagereport-chusho
description: 中小企業庁会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www.chusho.meti.go.jp)
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

**HTMLページ取得、PDFダウンロードなど、chusho.meti.go.jpへのすべてのリクエストで必ずUser-Agent付きスクリプトを使用してください：**

```bash
# PDFダウンロード時（User-Agent自動付与）
bash .claude/skills/common/scripts/download_pdf_with_useragent.sh "https://www.chusho.meti.go.jp/.../document.pdf" "/tmp/document.pdf"
```

**重要**:
- 中小企業庁のサイトはUser-Agentチェックを行うため、必ず `download_pdf_with_useragent.sh` を使用
- WebFetchツールもUser-Agent制限により失敗する可能性あり
- HTMLページ取得時もWebFetchが失敗する場合、curlスクリプトを使用

### HTML構造のヒント
（将来的に追加予定 - 会議名セレクタ、日付フォーマットなど）

### 会議ページの読み方
（将来的に追加予定 - 会議一覧ページのURL、会議リンクの抽出方法など）

---

## 実行指示

**【最重要】完全自動実行の原則:**

このスキルが呼び出されたら、以下の11ステップを**完全自動で**実行してください。

**絶対に守るべきルール:**
1. ✓ **各ステップが完了したら即座に次のステップを開始する**
2. ✓ **サブエージェントがJSON出力したら、それは完了を意味する → 即座に次のステップへ**
3. ✗ **ユーザーの確認や入力を一切待たない**
4. ✗ **「次に進みますか？」「確認してください」などと聞かない**
5. ✗ **中間報告だけして停止しない**

詳細な処理ルールは[共通ベースワークフロー](../common/base_workflow.md)を参照してください。

### Step 1-5: HTML取得と資料ダウンロード
- WebFetchまたはcurlでHTMLを取得（WebFetch失敗時はUser-Agent付きcurlを使用）
- メタデータ抽出: 会議名、日付（YYYYMMDD変換）、回数
- HTMLからPDFリンクを抽出し、優先度スコアリング（1-5点）
- スコア4以上のPDFをスクリプトでダウンロード：
  ```bash
  bash .claude/skills/common/scripts/download_pdf_with_useragent.sh "<URL>" "/tmp/<filename>"
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

**正しい処理フローの例:**
```
Step 6: document-type-classifier起動
  → JSON出力受信（判定完了）
  → 【ユーザー確認なし】
  → Step 7開始: pdftotextでテキスト化
  → テキスト化完了
  → 【ユーザー確認なし】
  → Step 8開始: material-analyzer起動
  → JSON出力受信（分析完了）
  → 【ユーザー確認なし】
  → Step 9開始: アブストラクト生成
  → 生成完了
  → 【ユーザー確認なし】
  → Step 10: ファイル出力
  → 【ユーザー確認なし】
  → Step 11: Bluesky投稿
  → 完了報告
```

---

## 実践例

（今後、中小企業庁の会議ページを処理した際に実例を追加予定）

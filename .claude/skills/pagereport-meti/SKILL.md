---
name: pagereport-meti
description: 経済産業省会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www.meti.go.jp)
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

**HTMLページ取得、PDFダウンロードなど、meti.go.jpへのすべてのリクエストで必ずUser-Agent付きスクリプトを使用してください：**

```bash
# PDFダウンロード時（User-Agent自動付与）
bash .claude/skills/common/scripts/download_pdf_with_useragent.sh "https://www.meti.go.jp/policy/.../document.pdf" "/tmp/document.pdf"
```

**重要**:
- 経済産業省のサイトはUser-Agentチェックを行うため、必ず `download_pdf_with_useragent.sh` を使用
- WebFetchツールもUser-Agent制限により失敗する可能性あり
- HTMLページ取得時もWebFetchが失敗する場合、curlスクリプトを使用

### HTML構造のヒント
（将来的に追加予定 - 会議名セレクタ、日付フォーマットなど）

### 会議ページの読み方
（将来的に追加予定 - 会議一覧ページのURL、会議リンクの抽出方法など）

---

## 実行指示

このスキルが呼び出されたら、以下の11ステップを**自動的に**実行してください。**人間の確認を求めず**、各ステップが完了したら即座に次のステップに進んでください。

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

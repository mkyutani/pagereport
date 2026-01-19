---
name: pagereport-digital
description: デジタル庁会議ページのサマリー作成（HTML+PDF対応、トークン最適化）。会議ページのURL、政府資料のPDF処理、議事録の要約作成
allowed-tools:
  - WebFetch(domain:www.digital.go.jp)
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
  - Read(path:./tmp/*)
  - Read(path:./output/*)
  - Write(path:./tmp/*)
  - Write(path:./output/*)
  - Edit(path:./tmp/*)
  - Edit(path:./output/*)
auto-execute: true
---

# デジタル庁 会議ページサマリー作成スキル

## 対象ドメイン
- www.digital.go.jp

## 府省庁固有の設定

### 府省庁識別子
```
digital
```

### HTML取得方法（Step 1用）

デジタル庁のサイトは標準的なHTMLページで、User-Agent制限はありません。

**content-acquirerサブエージェントへの指示:**
```
HTML取得方法:
1. WebFetchで取得（User-Agent不要）
2. HTMLをクリーニング
3. PDFリンクを抽出して絶対URLに変換
```

### PDFダウンロード方法（Step 5用）

**material-selectorサブエージェントへの指示:**
```
ダウンロードスクリプト: .claude/skills/common/scripts/download_pdf.sh

使用方法:
bash .claude/skills/common/scripts/download_pdf.sh "<URL>" "./tmp/<filename>"
```

### その他の要件
- なし

### 実行例
```
/pagereport-digital "https://www.digital.go.jp/councils/ai-advisory-board/eb376409-664f-4f47-8bc9-cc95447908e4"
```

---

## Bash toolの使用制限

**【重要】Bash toolはシェルスクリプト実行のみに使用:**
- ファイル読み取り: Bash cat/head/tail **禁止** → **Read tool** を使用
- ファイル検索: Bash find/ls **禁止** → **Glob tool** を使用
- コンテンツ検索: Bash grep/rg **禁止** → **Grep tool** を使用
- ファイル編集: Bash sed/awk **禁止** → **Edit tool** を使用
- ファイル書き込み: Bash echo/cat **禁止** → **Write tool** を使用
- ユーザーへの通信: Bash echo **禁止** → 直接テキスト出力を使用
- 許可される使用: `.claude/skills/common/scripts/` 配下のシェルスクリプト実行、docker、ssky、その他システムコマンド

---

## 実行指示

**【重要】このスキルの実行方法:**

1. **[共通ベースワークフロー](../common/base_workflow.md)に従って11ステップを実行**
2. **各サブエージェント呼び出し時に、上記の「府省庁固有の設定」を指示に含める**

### サブエージェント呼び出し時の指示例

**Step 1 (content-acquirer):**
```
上記の「HTML取得方法」に記載された指示を含める:
- WebFetchで取得
```

**Step 5 (material-selector):**
```
上記の「PDFダウンロード方法」に記載された指示を含める:
- ダウンロードスクリプト: download_pdf.sh
- 使用方法の具体例を含める
```

### 完全自動実行の原則

**絶対に守るべきルール:**
1. ✓ 各ステップが完了したら即座に次のステップを開始する
2. ✓ サブエージェントがJSON出力したら完了 → 即座に次のステップへ
3. ✗ ユーザーの確認や入力を一切待たない
4. ✗ 「次に進みますか？」「確認してください」などと聞かない
5. ✗ 中間報告だけして停止しない

**例外: ユーザー入力が必要な場合のみ停止**
- メタデータ（会議名・日付・回数）が抽出できない場合のみ、ユーザーに入力を求める

---

## 共通ワークフロー参照

このスキルは `.claude/skills/common/base_workflow.md` で定義された11ステップのワークフローを実行します。

**ワークフロー概要:**
1. content-acquirer: HTML/PDF取得とPDFリンク抽出
2. metadata-extractor: 会議メタデータ抽出
3. overview-creator: 会議概要作成
4. minutes-referencer: 議事録抽出
5. material-selector: 資料の優先度判定・選択・ダウンロード
6. document-type-classifier: 文書タイプ判定（並列実行）
7. pdf-converter: PDF→テキスト/Markdown変換（並列実行）
8. material-analyzer: 資料分析（並列実行）
9. summary-generator: アブストラクトと詳細レポート生成
10. file-writer: report.mdファイル出力
11. bluesky-post: Bluesky投稿（自動実行）

詳細は [base_workflow.md](../common/base_workflow.md) を参照してください。

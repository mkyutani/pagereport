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
  - Read(path:./tmp/*)
  - Read(path:./output/*)
  - Write(path:./tmp/*)
  - Write(path:./output/*)
  - Edit(path:./tmp/*)
  - Edit(path:./output/*)
auto-execute: true
---

# 中小企業庁 会議ページサマリー作成スキル

## 対象ドメイン
- www.chusho.meti.go.jp

## 府省庁固有の設定

### 府省庁識別子
```
chusho
```

### HTML取得方法（Step 1用）

**重要: User-Agent必須（WebFetchは使用しない）**

中小企業庁のサイトはUser-Agentベースのフィルタリングを実装しており、WebFetchは失敗します。タイムアウト待ちを避けるため、最初から専用のシェルスクリプトを使用してください。

**content-acquirerサブエージェントへの指示:**
```
HTML取得方法:
1. WebFetchは使用せず、HTMLフェッチスクリプトで取得:
   bash .claude/skills/common/scripts/step1/fetch_html_with_useragent.sh \
        "https://www.chusho.meti.go.jp/..." \
        "./tmp/chusho_page.html"
2. Readツールで ./tmp/chusho_page.html を読み込み
3. HTMLからPDFリンクを抽出して絶対URLに変換
```

### PDFダウンロード方法（Step 5用）

**material-selectorサブエージェントへの指示:**
```
ダウンロードスクリプト: .claude/skills/common/scripts/download_pdf_with_useragent.sh

使用方法:
bash .claude/skills/common/scripts/download_pdf_with_useragent.sh "<URL>" "./tmp/<filename>"
```

### その他の要件
- なし

### 実行例
```
/pagereport-chusho "https://www.chusho.meti.go.jp/koukai/kenkyukai/innovation_producer/003.html"
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
- WebFetchは使用せず、最初からシェルスクリプトで取得
- HTMLフェッチスクリプトの使用方法を含める
```

**Step 5 (material-selector):**
```
上記の「PDFダウンロード方法」に記載された指示を含める:
- ダウンロードスクリプト: download_pdf_with_useragent.sh
- 使用方法の具体例を含める
```

### 完全自動実行の原則

**絶対に守るべきルール:**
1. ✓ 各ステップが完了したら即座に次のステップを開始する
2. ✓ サブエージェントがJSON出力したら完了 → 即座に次のステップへ
3. ✗ ユーザーの確認や入力を一切待たない
4. ✗ 「次に進みますか？」「確認してください」などと聞かない
5. ✗ 中間報告だけして停止しない

---

## 実践例

（今後、中小企業庁の会議ページを処理した際に実例を追加予定）

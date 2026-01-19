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
  - Read(path:./tmp/*)
  - Read(path:./output/*)
  - Write(path:./tmp/*)
  - Write(path:./output/*)
  - Edit(path:./tmp/*)
  - Edit(path:./output/*)
auto-execute: true
---

# 経済産業省 会議ページサマリー作成スキル

## 対象ドメイン
- www.meti.go.jp

## 府省庁固有の設定

### 府省庁識別子
```
meti
```

### HTML取得方法（Step 1用）

**重要: User-Agent必須（WebFetchは使用しない）**

経済産業省のサイトはUser-Agentベースのフィルタリングを実装しており、WebFetchは失敗します。タイムアウト待ちを避けるため、最初からcurlを使用してください。

**content-acquirerサブエージェントへの指示:**
```
HTML取得方法:
1. WebFetchは使用せず、直接curlで取得:
   curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        "https://www.meti.go.jp/..." > ./tmp/meti_page.html
2. Readツールで./tmp/meti_page.htmlを読み込み
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
/pagereport-meti "https://www.meti.go.jp/shingikai/..."
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
- WebFetchは使用せず、直接curlで取得
- curlコマンドの具体例を含める
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
     grep "^#{1,3}\s+" ./tmp/003_03_00.md
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

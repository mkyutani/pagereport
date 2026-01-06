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

## 共通処理フロー

詳細な処理フローについては、[共通ベースワークフロー](../common/base_workflow.md) を参照してください。

### 処理概要

1. **コンテンツ取得**: HTMLページまたはPDFをWebFetchまたはReadツールで取得
2. **メタデータ抽出**: 会議名、日付、回数、場所を自動抽出
3. **文書タイプ判定**: PDFのタイプ（Word/PowerPoint/議事次第など）を判定
4. **会議概要作成**: HTMLまたは議事次第PDFから概要を抽出
5. **議事録参照**: 実際の発言内容を確認
6. **資料の選択的読み取り**: 優先度スコアリング（1-5点）で重要資料のみ選択
7. **効率的読み取り**: ページ数とタイプに応じたトークン最適化戦略
8. **要約生成**: 1,000字以内のアブストラクト + 詳細レポート
9. **ファイル出力**: `output/` ディレクトリに2種類のファイルを生成

会議名、開催日時、回数はHTMLから自動的に抽出されます。

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

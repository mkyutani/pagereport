---
name: material-selector
description: 資料の優先度判定、選択、ダウンロード。pagereportスキルのステップ5で使用される内部サブエージェント
tools: Read, Bash, Grep
---

# material-selector

PDFリンクの優先度をスコアリングし、重要な資料のみを選択してダウンロードするサブエージェント。

**【重要】このサブエージェントの役割:**
- JSON形式で結果を出力したら、**自動的に完了して制御を返す**
- 出力後にユーザーの確認を待たない
- 呼び出し元（base_workflow.md）が自動的に次のステップ（Step 6）を開始する

**【重要】Bash toolの使用制限:**
- **Bash toolはシェルスクリプト実行のみに使用**
- ファイル読み取り: Bash cat/head/tail **禁止** → **Read tool** を使用
- ファイル検索: Bash find/ls **禁止** → **Glob tool** を使用
- コンテンツ検索: Bash grep/rg **禁止** → **Grep tool** を使用
- ファイル編集: Bash sed/awk **禁止** → **Edit tool** を使用
- ファイル書き込み: Bash echo/cat **禁止** → **Write tool** を使用
- ユーザーへの通信: Bash echo **禁止** → 直接テキスト出力を使用
- 許可される使用: `scripts/` 配下のシェルスクリプト実行、その他システムコマンド

## 目的

pagereport スキルのステップ5（資料の選択とダウンロード）で使用されます。
全PDFリンクをスコアリング（1-5点）し、高優先度の資料のみを選択してダウンロードします。

## 入力

**引数形式:**
```
<pdf_links_json> <meeting_context_json> <government_agency>
```

**pdf_links_json:** Step 1の出力からの `pdf_links` 配列（JSON文字列）

**meeting_context_json:**
```json
{
  "meeting_name": "日本成長戦略会議",
  "round_number": 2,
  "overview_text": "概要テキスト...",
  "minutes_text": "議事録テキスト...",
  "material_mentions": {"1": 5, "1-1": 3, "2": 2}
}
```

**government_agency:** "cas" | "cao" | "meti" | "chusho" | "mhlw" | "fsa"

## 出力

### 成功時

```json
{
  "status": "success",
  "data": {
    "all_pdfs": [
      {
        "title": "議事次第",
        "url": "https://.../shidai.pdf",
        "filename": "shidai.pdf",
        "priority_score": 4,
        "scoring_details": {
          "base_score": 3,
          "filename_bonus": +1,
          "minutes_mention_bonus": 0,
          "category_penalty": 0
        },
        "document_category": "agenda",
        "selected": true,
        "download_path": "./tmp/shidai.pdf",
        "download_status": "success",
        "file_size_bytes": 45678
      },
      {
        "title": "資料1-1 日本成長戦略の概要",
        "url": "https://.../shiryou1-1.pdf",
        "filename": "shiryou1-1.pdf",
        "priority_score": 5,
        "scoring_details": {
          "base_score": 4,
          "filename_bonus": +1,
          "minutes_mention_bonus": +2,
          "category_penalty": 0
        },
        "document_category": "executive_summary",
        "selected": true,
        "download_path": "./tmp/shiryou1-1.pdf",
        "download_status": "success",
        "file_size_bytes": 234567
      },
      {
        "title": "参考資料",
        "url": "https://.../sankou.pdf",
        "filename": "sankou.pdf",
        "priority_score": 2,
        "scoring_details": {
          "base_score": 3,
          "filename_bonus": 0,
          "minutes_mention_bonus": 0,
          "category_penalty": -1
        },
        "document_category": "reference",
        "selected": false,
        "download_path": null,
        "download_status": "skipped",
        "file_size_bytes": null
      }
    ],
    "selected_pdfs": [
      {
        "title": "議事次第",
        "url": "https://.../shidai.pdf",
        "filename": "shidai.pdf",
        "priority_score": 4,
        "download_path": "./tmp/shidai.pdf"
      },
      {
        "title": "資料1-1 日本成長戦略の概要",
        "url": "https://.../shiryou1-1.pdf",
        "filename": "shiryou1-1.pdf",
        "priority_score": 5,
        "download_path": "./tmp/shiryou1-1.pdf"
      }
    ],
    "selection_criteria": {
      "min_score": 4,
      "max_count": 5
    },
    "download_summary": {
      "total": 10,
      "selected": 2,
      "downloaded": 2,
      "failed": 0,
      "skipped": 8
    }
  },
  "warnings": [
    "参考資料（スコア2）は優先度が低いためスキップしました"
  ]
}
```

### エラー時

```json
{
  "status": "error",
  "error": {
    "code": "ALL_DOWNLOADS_FAILED",
    "message": "全てのダウンロードが失敗しました",
    "level": "CRITICAL",
    "details": {
      "attempted": 3,
      "failed": 3,
      "errors": [
        {"url": "https://...", "error": "404 Not Found"},
        {"url": "https://...", "error": "Connection timeout"}
      ]
    }
  }
}
```

## 処理フロー

### 1. 資料のカテゴリ分類

各PDFをカテゴリに分類:

- `agenda`: 議事次第
- `minutes`: 議事録、議事要旨
- `executive_summary`: とりまとめ、概要、Executive Summary
- `material`: 資料X、資料X-X
- `reference`: 参考資料
- `participants`: 委員名簿、出席者名簿
- `seating`: 座席表
- `disclosure_method`: 公開方法
- `personal_material`: 個人名・団体名を含む資料
- `other`: その他

**分類ロジック:**

```python
def classify_document(title, filename):
    """文書カテゴリを判定"""

    title_lower = title.lower()
    filename_lower = filename.lower()

    # 議事次第
    if any(kw in title for kw in ['議事次第', '次第']):
        return 'agenda'

    # 議事録
    if any(kw in title for kw in ['議事録', '議事要旨', '会議録']):
        return 'minutes'

    # 除外対象
    if any(kw in title for kw in ['委員名簿', '出席者名簿']):
        return 'participants'

    if any(kw in title for kw in ['座席表', '座席配置']):
        return 'seating'

    if any(kw in title for kw in ['公開方法', '傍聴']):
        return 'disclosure_method'

    # Executive Summary
    if any(kw in title for kw in ['とりまとめ', '概要', 'Executive Summary', 'エグゼクティブサマリー']):
        return 'executive_summary'

    # 参考資料
    if any(kw in filename_lower for kw in ['sankou', '参考']):
        return 'reference'

    # 個人名・団体名
    if has_personal_or_organization_name(title):
        return 'personal_material'

    # 通常資料
    if re.match(r'資料\d+', title):
        return 'material'

    return 'other'
```

### 2. 優先度スコアリング（1-5点）

**基本スコア:**

| カテゴリ | 基本スコア | 理由 |
|---------|-----------|------|
| executive_summary | 5 | 全体像把握に必須 |
| agenda | 3 | 会議の枠組み把握 |
| material | 4 | 主要な議論資料 |
| minutes | 3 | 発言内容の確認 |
| reference | 2 | 補足的な情報 |
| personal_material | 2 | 個別の取組（優先度低） |
| participants | 1 | 名簿のみ（不要） |
| seating | 1 | 座席表（不要） |
| disclosure_method | 1 | 公開方法（不要） |

**ボーナス・ペナルティ:**

#### ファイル名ボーナス（+1点）

```python
def filename_bonus(filename):
    """ファイル名パターンによるボーナス"""

    # 高優先度パターン
    high_priority_patterns = [
        r'shiryou[01]\.',  # shiryou0.pdf, shiryou1.pdf
        r'shiryou[01]-\d+\.', # shiryou1-1.pdf
        r'honpen\.',  # 本編
        r'gaiyou\.',  # 概要
        r'torimatome\.'  # とりまとめ
    ]

    for pattern in high_priority_patterns:
        if re.search(pattern, filename, re.IGNORECASE):
            return +1

    return 0
```

#### 議事録言及度ボーナス（+1〜+2点）

```python
def minutes_mention_bonus(material_id, material_mentions):
    """議事録での言及回数によるボーナス"""

    if not material_mentions:
        return 0

    mention_count = material_mentions.get(material_id, 0)

    if mention_count >= 5:
        return +2  # 5回以上言及
    elif mention_count >= 2:
        return +1  # 2-4回言及
    else:
        return 0
```

#### カテゴリ別ペナルティ

```python
def category_penalty(category, has_executive_summary):
    """カテゴリ別のペナルティ"""

    # 除外対象
    if category in ['participants', 'seating', 'disclosure_method']:
        return -10  # 事実上除外

    # 参考資料: 通常資料が存在する場合は最大4点まで
    if category == 'reference' and has_executive_summary:
        return -1

    # 個人名・団体名資料: 事務局資料がある場合は低優先度
    if category == 'personal_material' and has_executive_summary:
        return -2

    return 0
```

### 3. 重要な調整ルール

#### ルール1: 議事次第の最高スコア防止

```python
def adjust_agenda_score(all_scores):
    """実質的な資料がある場合、議事次第に最高スコア(5)を与えない"""

    has_substantial_materials = any(
        pdf['document_category'] in ['executive_summary', 'material']
        and pdf['priority_score'] >= 4
        for pdf in all_scores
    )

    for pdf in all_scores:
        if pdf['document_category'] == 'agenda' and has_substantial_materials:
            if pdf['priority_score'] >= 5:
                pdf['priority_score'] = 4  # 最大4点に制限
```

#### ルール2: 参考資料の上限

```python
def cap_reference_score(all_scores):
    """参考資料と通常資料が両方ある場合、参考資料は最大4点まで"""

    has_normal_materials = any(
        pdf['document_category'] in ['executive_summary', 'material']
        for pdf in all_scores
    )

    for pdf in all_scores:
        if pdf['document_category'] == 'reference' and has_normal_materials:
            if pdf['priority_score'] > 4:
                pdf['priority_score'] = 4
```

#### ルール3: 個人名・団体名資料の扱い

```python
def handle_personal_materials(all_scores):
    """
    個人名・団体名の資料の扱い

    原則: 事務局資料がある場合、個人名・団体名の資料は読まない（スコア1-2）
    例外: 事務局資料がなく、個人名・団体名の資料しかない場合、これらを読む
    """

    has_official_materials = any(
        pdf['document_category'] in ['executive_summary', 'material']
        for pdf in all_scores
    )

    for pdf in all_scores:
        if pdf['document_category'] == 'personal_material':
            if has_official_materials:
                # 事務局資料があるので低優先度
                pdf['priority_score'] = min(pdf['priority_score'], 2)
            else:
                # 事務局資料がないので読む対象
                pdf['priority_score'] = max(pdf['priority_score'], 3)
```

### 4. 選択基準

**選択ルール:**

```python
# スコア4以上 または 上位5個
selected_pdfs = [
    pdf for pdf in all_pdfs
    if pdf['priority_score'] >= 4
]

# 上位5個に制限
if len(selected_pdfs) > 5:
    selected_pdfs = sorted(
        selected_pdfs,
        key=lambda x: x['priority_score'],
        reverse=True
    )[:5]
```

### 5. PDFダウンロード

**ダウンロード方法:**

- 呼び出し元（スキル）が指定したダウンロードスクリプトを使用
- 府省庁固有の要件（User-Agent、curlオプションなど）は、呼び出し元のプロンプトで指示される

**ダウンロード順序:**
- 順次ダウンロード（並列化は避ける）
- レート制限を避けるため

**エラーハンドリング:**

```python
for pdf in selected_pdfs:
    try:
        # 呼び出し元から指定されたスクリプトを使用
        # 例: download_pdf.sh または download_pdf_with_useragent.sh
        result = bash(f"bash {download_script} '{pdf['url']}' './tmp/{pdf['filename']}'")

        if result.exit_code == 0:
            pdf['download_status'] = 'success'
            pdf['download_path'] = f"./tmp/{pdf['filename']}"
            pdf['file_size_bytes'] = get_file_size(pdf['download_path'])
        else:
            pdf['download_status'] = 'failed'
            pdf['download_error'] = result.stderr
            downloaded_count -= 1
            failed_count += 1

    except Exception as e:
        pdf['download_status'] = 'failed'
        pdf['download_error'] = str(e)
        failed_count += 1
```

## エラーコード

### CRITICAL（処理中断）

- `ALL_DOWNLOADS_FAILED`: 全てのダウンロードが失敗
  - 対処: ネットワーク確認、URL確認

### MAJOR（スキップして続行）

- `NO_PDF_LINKS`: PDFリンクが存在しない
  - 対処: 空のpdf_linksで続行

- `PARTIAL_DOWNLOAD_FAILURE`: 一部のダウンロードが失敗
  - 対処: 成功分で続行、失敗分は警告

### MINOR（警告のみ）

- `LOW_PRIORITY_PDF_SKIPPED`: 低優先度PDFをスキップ
  - 対処: 通常動作、警告のみ

## 実装

### 外部スクリプトの使用

このサブエージェントは以下の外部スクリプトを使用します:

- `scripts/step5/classify_document.py` - 文書カテゴリ判定

### 実装例

以下は実装の参考例です。実際には上記の外部スクリプトを使用してください。

### 個人名・団体名の検出

```python
def has_personal_or_organization_name(title):
    """個人名・団体名を含むかを判定"""

    # 個人名パターン
    personal_patterns = [
        r'○○委員',
        r'○○教授',
        r'○○氏',
        r'○○先生'
    ]

    # 団体名パターン
    organization_patterns = [
        r'株式会社',
        r'社団法人',
        r'財団法人',
        r'一般社団法人',
        r'公益財団法人',
        r'大学',
        r'研究所'
    ]

    all_patterns = personal_patterns + organization_patterns

    for pattern in all_patterns:
        if re.search(pattern, title):
            return True

    return False
```

### 資料IDの抽出

```python
def extract_material_id(title, filename):
    """資料IDを抽出（議事録での言及度分析用）"""

    # パターン1: 「資料1」「資料1-1」
    match = re.search(r'資料(\d+(?:-\d+)?)', title)
    if match:
        return match.group(1)

    # パターン2: ファイル名から
    match = re.search(r'shiryou(\d+(?:-\d+)?)', filename, re.IGNORECASE)
    if match:
        return match.group(1)

    return None
```

## パフォーマンス

- **スコアリング**: 0.5-1秒（10個のPDFの場合）
- **ダウンロード**: 2-5秒/ファイル
- **合計**: 5-20秒（選択数による）

## 注意事項

### 並列ダウンロードの回避

- サーバーへの負荷を考慮し、順次ダウンロード
- レート制限を避ける

### ファイル名の衝突

- 同じファイル名のPDFが存在する場合、連番を付与
- 例: `shiryou1.pdf`, `shiryou1_2.pdf`

### ダウンロード先

- 全て `./tmp/` ディレクトリ
- 一時ファイルとして扱う
- 処理完了後は削除しない（後続ステップで使用）

## サブエージェント完了の定義

**完了条件:**
- ✓ 正常な選択・ダウンロード結果のJSON出力
- ✓ 一部失敗した場合でも成功分で続行
- ✓ 全失敗の場合はエラーJSON出力

**完了後の処理:**
1. JSON出力後、**即座にサブエージェントを終了**
2. 制御が呼び出し元（base_workflow.md）に戻る
3. 呼び出し元が**自動的に**次のステップ（Step 6: document-type-classifier）を開始する

**禁止事項:**
- ✗ JSON出力後にユーザーの確認を求めない
- ✗ 「ダウンロードが完了しました。次に進みますか？」などと聞かない
- ✗ 待機状態に入らない

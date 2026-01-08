# pagereport

政府会議ページのサマリー作成スキル（HTML+PDF対応、トークン最適化、Bluesky連携）

## 概要

このプロジェクトは、日本の政府会議ページから構造化されたサマリーを生成する Claude Code スキル群です。HTMLページとPDFドキュメントの両方に対応し、会議資料を並列分析して統合レポートファイルを生成します。生成されたアブストラクトは自動的にBlueskyに投稿されます。

## 主な機能

- **複数の政府機関に対応**: 内閣官房（CAS）、内閣府（CAO）、経済産業省（METI）、中小企業庁（Chusho）、厚生労働省（MHLW）、金融庁（FSA）
- **並列処理による高速化**: 文書タイプ検出と資料分析を並列実行（30-50%の処理時間短縮）
- **自動メタデータ抽出**: 会議名、日付（YYYYMMDD形式に変換）、回数、開催場所を自動抽出
- **PDF優先度付けシステム**: 関連性、重要性、文書タイプに基づいてPDFをスコアリング（1-5）
- **文書タイプ別処理**: Word（pdftotext）、PowerPoint（docling）を最適な方法で処理
- **トークン最適化**: ページ数と文書タイプに応じた動的な読み取り戦略
- **Bluesky自動投稿**: 生成されたアブストラクトを自動的にBlueskyに投稿

## 使い方

### 基本的な使用方法

```bash
# 内閣官房（CAS）の会議ページを処理
/pagereport-cas "https://www.cas.go.jp/jp/seisaku/nipponseichosenryaku/kaigi/dai2/gijisidai.html"

# 内閣府（CAO）の会議ページを処理
/pagereport-cao "https://www.cao.go.jp/..."

# 経済産業省（METI）の会議ページを処理
/pagereport-meti "https://www.meti.go.jp/..."

# 中小企業庁（Chusho）の会議ページを処理
/pagereport-chusho "https://www.chusho.meti.go.jp/..."

# 厚生労働省（MHLW）の会議ページを処理
/pagereport-mhlw "https://www.mhlw.go.jp/..."

# 金融庁（FSA）の会議ページを処理
/pagereport-fsa "https://www.fsa.go.jp/..."
```

### Bluesky投稿

スキル実行時に自動的にBlueskyに投稿されます。手動で投稿する場合：

```bash
# 既存のレポートをBlueskyに投稿
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

**初回セットアップ**:
```bash
# sskyをインストール
pip install ssky

# Blueskyにログイン
ssky login

# ログイン状態を確認
ssky profile myself
```

## 出力形式

### レポートファイル（`*_report.md`）

単一のMarkdownファイルに以下の内容を統合：

1. **会議メタデータ**: 会議名、開催日時、場所、URL
2. **アブストラクト**（コードフェンスで囲まれた1,000文字の要約）:
   - 背景・文脈（2-3文）- **会議名と回数を含む**
   - 目的（1-2文）
   - 議論内容（3-5文）
   - 決定事項・合意事項（3-5文）
   - 今後の方向性（2-3文）
3. **資料リスト**: 各資料のタイトル、ページ数、優先度スコア
4. **詳細情報**: 最大10,000文字の包括的なレポート

### ファイル配置

```
output/
└── {会議名}_第{N}回_{YYYYMMDD}_report.md
```

例:
```
output/
└── 日本成長戦略会議_第2回_20251224_report.md
```

## アーキテクチャ

### 処理パイプライン（11ステップ）

1. **コンテンツ取得**: WebFetchでHTML取得、またはローカル/リモートPDF読み取り
2. **メタデータ抽出**: 会議名、日付、回数、場所を自動抽出
3. **会議概要作成**: HTMLまたは議事次第PDFから抽出
4. **議事録参照**: 実際の発言内容を探索
5. **資料の選択とダウンロード**: 関連性でPDFをスコアリング、優先度の高いファイルをcurlで`/tmp/`にダウンロード
6. **文書タイプ検出** ⚡️ **並列処理**: `document-type-classifier`サブエージェントで複数PDFを並列判定
7. **PDF to Markdown変換**: docling（PowerPoint）またはpdftotext（Word）でトークン最適化
8. **タイプ別読み取り** ⚡️ **並列処理**: `material-analyzer`サブエージェントで複数資料を並列分析
9. **サマリー生成**: 構造化された要約（1,000文字、5要素構造）+ 詳細レポート作成
10. **ファイル出力**: `{会議名}_第{N}回_{YYYYMMDD}_report.md`を生成
11. **Bluesky投稿**: アブストラクトを自動的にBlueskyに投稿

### PDF処理戦略

**Word文書（線形テキスト構造）**:
- `pdftotext`を使用（高速、10-50倍）
- 線形読み取りで十分な文書に最適

**PowerPoint文書（構造保存が必要）**:
- `docling`を使用（構造保存）
- スライド、箇条書き、レイアウトを保持

**その他の文書**:
- サイズに応じてpdftotext、docling、またはRead toolを使用

### 並列処理による高速化

- **文書タイプ検出（Step 6）**: 複数のPDFを同時に分類
- **資料分析（Step 8）**: 複数の資料を同時に分析
- **処理時間短縮**: 3つ以上の資料を扱う場合、30-50%の時間短縮

## プロジェクト構成

```
.
├── .claude/
│   ├── skills/
│   │   ├── pagereport-cas/          # 内閣官房スキル
│   │   │   └── SKILL.md
│   │   ├── pagereport-cao/          # 内閣府スキル
│   │   │   └── SKILL.md
│   │   ├── pagereport-meti/         # 経済産業省スキル
│   │   │   └── SKILL.md
│   │   ├── pagereport-chusho/       # 中小企業庁スキル
│   │   │   └── SKILL.md
│   │   ├── pagereport-mhlw/         # 厚生労働省スキル
│   │   │   └── SKILL.md
│   │   ├── pagereport-fsa/          # 金融庁スキル
│   │   │   └── SKILL.md
│   │   ├── bluesky-post/            # Bluesky投稿スキル
│   │   │   ├── SKILL.md
│   │   │   └── post.sh
│   │   ├── document-type-classifier/ # 文書タイプ検出サブエージェント
│   │   │   └── SKILL.md
│   │   ├── material-analyzer/       # 資料分析サブエージェント
│   │   │   └── SKILL.md
│   │   └── common/
│   │       └── base_workflow.md     # 共通ワークフロー（11ステップ）
│   └── settings.local.json          # 権限設定
├── CLAUDE.md                        # Claude Code向けガイダンス（詳細仕様）
├── README.md                        # このファイル
└── output/                          # 生成されたレポートファイル（.gitignoreで除外）
```

## 技術仕様

### 必要な権限

`.claude/settings.local.json`で以下の権限を事前承認：

- `WebFetch(domain:*.go.jp)`: 政府サイトからのコンテンツ取得
- `Bash(curl:*)`: PDFダウンロード
- `Bash(pdftotext:*)`: Word PDF処理
- `Bash(docker:*)`: docling（PowerPoint PDF処理）
- `Bash(ssky:*)`: Bluesky投稿
- `Read/Write/Edit(path:/tmp/*)`: 一時ファイル操作
- `Read/Write/Edit(path:./output/*)`: 出力ファイル操作

### 依存ツール

- **pdftotext**: Word PDF処理（`apt-get install poppler-utils`）
- **docling**: PowerPoint PDF処理（Docker: `quay.io/docling-project/docling-serve`）
- **ssky**: Bluesky投稿（`pip install ssky`）

## 開発

### ワークフローの編集

`.claude/skills/common/base_workflow.md`を編集する場合:

- 11ステップ構造を維持
- 異なる文書タイプを処理する場合はトークン最適化戦略を更新
- 観察された関連性パターンに基づいてPDFスコアリング基準を調整
- 要約構造を厳密に保持（5要素、1段落、1,000文字）
- 実際の政府会議ページでテストして変更を検証

### 新しいスキルの追加

1. `.claude/skills/<skill-name>/SKILL.md`を作成
2. 共通ワークフローを参照: `../common/base_workflow.md`
3. ドメイン固有のカスタマイズを追加
4. `.claude/settings.local.json`でドメイン権限を更新
5. `CLAUDE.md`にドキュメント化

### GitHubワークフロー

**ブランチ戦略**:
- `main`ブランチは常に安定版
- 機能追加は`feature/`ブランチで作業
- Pull Requestを通じてマージ

**コミットメッセージ形式** (Conventional Commits):
```
<type>: <subject>

[optional body]
```

タイプ: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`

詳細は`CLAUDE.md`を参照してください。

## トラブルシューティング

### Bluesky投稿がスキップされる

```bash
# ログイン状態を確認
ssky profile myself

# 再ログイン
ssky login

# 手動で投稿
/bluesky-post "output/日本成長戦略会議_第2回_20251224_report.md"
```

### pdftotext が見つからない

```bash
# インストール（Debian/Ubuntu）
apt-get install poppler-utils

# 確認
which pdftotext
```

### docling コンテナが起動しない

```bash
# コンテナの状態を確認
docker ps | grep docling

# コンテナを起動
docker start docling-server

# 初回起動
docker run -d -p 5001:5001 --name docling-server quay.io/docling-project/docling-serve
```

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 関連リンク

- [Claude Code](https://claude.com/claude-code)
- [ssky (Bluesky CLI)](https://github.com/simpleskyclient/ssky)
- [docling (PDF to Markdown)](https://github.com/DS4SD/docling)

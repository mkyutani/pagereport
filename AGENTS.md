# Repository Guidelines

## プロジェクト構成とモジュール配置
- `codex/` にスキルが配置されています。主なファイルは `codex/pagereport-orchestrator/SKILL.md`（オーケストレーター）、`codex/pagereport-subagents/`（11のサブエージェント参照）、`codex/*/SKILL.md`（スキル入口）です。
- `output/` に生成レポートが `{meeting_name}_第{N}回_{YYYYMMDD}_report.md` 形式で保存されます。
- `tmp/` は一時ダウンロード・変換用です。
- `README.md` と `CLAUDE.md` に動作仕様と制約がまとまっています。

## スキル一覧と概要
### オーケストレーター
- `codex/pagereport-orchestrator/SKILL.md`: 11ステップのpagereportワークフロー全体を統括し、サブエージェント間のJSON受け渡しを管理。

### pagereport サブエージェント（11）
- `codex/subagents/content-acquirer.md`: HTML/PDF取得、HTMLクリーニング、PDFリンク抽出。
- `codex/subagents/metadata-extractor.md`: 会議名・日付・回数・場所などのメタデータ抽出。
- `codex/subagents/page-type-detector.md`: 会議ページ/報告書ページの判定。
- `codex/subagents/overview-creator.md`: 会議概要・議題・出席者の抽出。
- `codex/subagents/minutes-referencer.md`: 議事録の検出と発言内容抽出。
- `codex/subagents/material-selector.md`: 資料の優先度判定とダウンロード。
- `codex/subagents/document-type-classifier.md`: PDF文書タイプ判定（Word/PPT等）。
- `codex/subagents/pdf-converter.md`: 文書タイプ別のPDF変換（pdftotext/docling）。
- `codex/subagents/material-analyzer.md`: 変換済み資料の分析・要約生成。
- `codex/subagents/summary-generator.md`: アブストラクトと詳細レポート生成。
- `codex/subagents/file-writer.md`: レポートを`output/`に書き出し。

### リファレンス
- `codex/pagereport-orchestrator/references/base_workflow.md`: 11ステップの標準ワークフロー。
- `codex/pagereport-orchestrator/references/subagent-conventions.md`: サブエージェントの共通規約。
- `codex/pagereport-subagents/references/subagent-conventions.md`: サブエージェントの共通規約（サブエージェント入口側）。

### スキル入口（codex/*/SKILL.md）
- `codex/pagereport-cas/SKILL.md`: 内閣官房（cas）向け。HTMLはWebFetch可、PDFは標準ダウンロード。
- `codex/pagereport-cao/SKILL.md`: 内閣府（cao）向け。HTMLはWebFetch可、PDFは標準ダウンロード。
- `codex/pagereport-meti/SKILL.md`: 経産省（meti）向け。HTML取得・PDFダウンロードはUser-Agent必須。
- `codex/pagereport-chusho/SKILL.md`: 中小企業庁（chusho）向け。HTML取得は専用スクリプト、PDFはUser-Agent必須。
- `codex/pagereport-mhlw/SKILL.md`: 厚労省（mhlw）向け。HTMLはWebFetch可、PDFはUser-Agent必須。
- `codex/pagereport-fsa/SKILL.md`: 金融庁（fsa）向け。HTMLはWebFetch可、PDFはUser-Agent必須。
- `codex/pagereport-digital/SKILL.md`: デジタル庁（digital）向け。HTMLはWebFetch可、PDFは標準ダウンロード。
- `codex/bluesky-post/SKILL.md`: レポートからアブストラクト抽出してBluesky投稿。
- `codex/github-workflow/SKILL.md`: ブランチ/コミット/PR規約。

## codex/ 配下のスキルと scripts 一覧
### スキル（SKILL.md）
- `codex/bluesky-post/SKILL.md`: レポートのアブストラクトを抽出してBluesky投稿。
- `codex/github-workflow/SKILL.md`: ブランチ/コミット/PRの規約。
- `codex/pagereport-cao/SKILL.md`: 内閣府（cao）会議ページ向けレポート生成。
- `codex/pagereport-cas/SKILL.md`: 内閣官房（cas）会議ページ向けレポート生成。
- `codex/pagereport-chusho/SKILL.md`: 中小企業庁（chusho）会議ページ向けレポート生成（User-Agent必須）。
- `codex/pagereport-digital/SKILL.md`: デジタル庁（digital）会議ページ向けレポート生成。
- `codex/pagereport-fsa/SKILL.md`: 金融庁（fsa）会議ページ向けレポート生成（PDFはUser-Agent必須）。
- `codex/pagereport-meti/SKILL.md`: 経産省（meti）会議ページ向けレポート生成（User-Agent必須）。
- `codex/pagereport-mhlw/SKILL.md`: 厚労省（mhlw）会議ページ向けレポート生成（PDFはUser-Agent必須）。
- `codex/pagereport-orchestrator/SKILL.md`: 11ステップのpagereportワークフロー統括。
- `codex/pagereport-subagents/SKILL.md`: 11サブエージェントのガイドと入口。

### scripts（codex/**/scripts）
- `codex/bluesky-post/scripts/post.sh`: レポートからアブストラクトを抽出してBlueskyに投稿。
- `codex/common/scripts/check_tool.sh`: 指定ツールの存在確認。
- `codex/common/scripts/convert_pdf.py`: docling-serveでPDFをMarkdownへ変換。
- `codex/common/scripts/convert_pdftotext.sh`: pdftotextでPDFをテキスト変換。
- `codex/common/scripts/convert_pdftotext_fallback.sh`: PyPDF2でPDFをテキスト変換（フォールバック）。
- `codex/common/scripts/docling_convert_async.sh`: doclingの非同期変換を開始してTASK_IDを返す。
- `codex/common/scripts/docling_get_result.sh`: docling変換結果を取得してMarkdown保存。
- `codex/common/scripts/docling_poll_status.sh`: docling変換ステータスをポーリング。
- `codex/common/scripts/download_pdf.sh`: PDFを通常ダウンロード。
- `codex/common/scripts/download_pdf_with_useragent.sh`: User-Agent付きでPDFをダウンロード。
- `codex/common/scripts/extract_images_from_md.sh`: Markdown内のbase64画像を抽出して除去。
- `codex/common/scripts/extract_important_pages.sh`: Markdownから指定ページのみを抽出。
- `codex/common/scripts/fetch_html_with_useragent.sh`: User-Agent付きでHTMLを取得。
- `codex/common/scripts/make_absolute_urls.py`: PDFリンクの相対URLを絶対URL化しファイル名付与。
- `codex/common/scripts/convert_era_to_western.py`: 元号/西暦の日付をYYYYMMDDに変換。
- `codex/common/scripts/normalize_meeting_name.py`: 会議名から「第X回」等を除去して正規化。
- `codex/common/scripts/extract_speakers.py`: 議事録から発言者を抽出・集計。
- `codex/common/scripts/classify_document.py`: タイトル/ファイル名から文書カテゴリを判定。
- `codex/common/scripts/validate_abstract_structure.py`: アブストラクトの5要素構造を検証。
- `codex/common/scripts/create_output_directory.sh`: outputディレクトリを作成。
- `codex/common/scripts/validate_filename.py`: 出力ファイル名の妥当性を検証。

## ビルド・テスト・開発コマンド
- スキル実行（Claude Code）:
  - `/pagereport-cas "https://www.cas.go.jp/..."`（他: `pagereport-cao`, `-meti`, `-chusho`, `-mhlw`, `-fsa`, `-digital`）
  - `/bluesky-post "output/<report>_report.md"` で既存レポートを投稿
- 補助ツール: `pdftotext`, `docker`（docling）, `ssky` を使用。必要に応じて `README.md` の手順でインストールします。

## コーディングスタイルと命名規則
- `codex/subagents/` のサブエージェントは自己完結・JSON入出力を維持し、YAMLフロントマターがあれば保持します。
- `codex/pagereport-orchestrator/references/base_workflow.md` の 11 ステップ構造は維持してください。
- 出力ファイル命名は `{meeting_name}_第{N}回_{YYYYMMDD}_report.md` を厳守し、`output/` に保存します。
- サマリーは簡潔・事実ベース。推測は避けます（詳細は `CLAUDE.md`）。

## テスト方針
- 自動テストは未定義。実際の政府会議ページでスキルを実行し、`output/` のレポートを確認します。
- アブストラクトを変更した場合、5要素・1段落・1,000文字上限を必ず確認してください。

## コミットとプルリクエスト
- ブランチ: `feature/<desc>`, `fix/<desc>`, `docs/<desc>`, `refactor/<desc>`。`main` への直コミットは禁止。
- Conventional Commits 必須（`feat:`, `fix:`, `docs:` など）。命令形・72文字以内・末尾ピリオドなし。
- PR には「変更内容と理由」「関連Issue」「実施したテスト」「破壊的変更の有無」を記載し、自己レビューを推奨します。

## セキュリティと設定
- Bluesky 投稿はベストエフォートのため、`ssky` ログイン設定を事前に確認してください。
- `ssky` はエスカレーションなしで実行する。

## コマンド実行時の確認
- `rm` / `rmdir` / `del` / `delete` など削除系コマンド以外は、ユーザー確認なしで実行してよい。

## スキル運用
- `*.go.jp` のサイトをまとめたり要約したりする指示があれば、適切な府省庁のスキルを追加で使う。

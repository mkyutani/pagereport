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
- `codex/pagereport-subagents/references/agents/content-acquirer.md`: HTML/PDF取得、HTMLクリーニング、PDFリンク抽出。
- `codex/pagereport-subagents/references/agents/metadata-extractor.md`: 会議名・日付・回数・場所などのメタデータ抽出。
- `codex/pagereport-subagents/references/agents/page-type-detector.md`: 会議ページ/報告書ページの判定。
- `codex/pagereport-subagents/references/agents/overview-creator.md`: 会議概要・議題・出席者の抽出。
- `codex/pagereport-subagents/references/agents/minutes-referencer.md`: 議事録の検出と発言内容抽出。
- `codex/pagereport-subagents/references/agents/material-selector.md`: 資料の優先度判定とダウンロード。
- `codex/pagereport-subagents/references/agents/document-type-classifier.md`: PDF文書タイプ判定（Word/PPT等）。
- `codex/pagereport-subagents/references/agents/pdf-converter.md`: 文書タイプ別のPDF変換（pdftotext/docling）。
- `codex/pagereport-subagents/references/agents/material-analyzer.md`: 変換済み資料の分析・要約生成。
- `codex/pagereport-subagents/references/agents/summary-generator.md`: アブストラクトと詳細レポート生成。
- `codex/pagereport-subagents/references/agents/file-writer.md`: レポートを`output/`に書き出し。

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

## ビルド・テスト・開発コマンド
- スキル実行（Claude Code）:
  - `/pagereport-cas "https://www.cas.go.jp/..."`（他: `pagereport-cao`, `-meti`, `-chusho`, `-mhlw`, `-fsa`, `-digital`）
  - `/bluesky-post "output/<report>_report.md"` で既存レポートを投稿
- 補助ツール: `pdftotext`, `docker`（docling）, `ssky` を使用。必要に応じて `README.md` の手順でインストールします。

## コーディングスタイルと命名規則
- `codex/pagereport-subagents/references/agents/` のサブエージェントは自己完結・JSON入出力を維持し、YAMLフロントマターがあれば保持します。
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

# Subagent Common Conventions

このドキュメントは、pagereportワークフローの全サブエージェントが従うべき共通規約を定義します。

## 基本原則

### 1. 即座完了
- JSON形式で結果を出力したら**即座に終了**
- ユーザーの確認を待たない
- 「次に進みますか？」などと聞かない

### 2. 標準化されたJSON出力

**成功時:**
```json
{
  "status": "success",
  "data": {
    // ステップ固有のデータ
  }
}
```

**エラー時:**
```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーの説明",
    "level": "CRITICAL" | "MAJOR" | "MINOR"
  }
}
```

**警告付き成功:**
```json
{
  "status": "success",
  "data": {...},
  "warnings": ["警告メッセージ1", "警告メッセージ2"]
}
```

### 3. エラーレベル

- **CRITICAL**: 処理を中断（オーケストレータが停止）
  - 例: メタデータ取得失敗、必須ファイルが存在しない

- **MAJOR**: そのステップをスキップして続行
  - 例: PDF読み取り失敗、変換失敗

- **MINOR**: 警告を出すが続行
  - 例: Bluesky投稿失敗、画像抽出失敗

### 4. ステートレス設計

- サブエージェントは状態を持たない
- 入力JSONだけで動作可能
- 他のサブエージェントに依存しない

## YAML Frontmatter（必須）

各サブエージェントのSKILL.mdには以下を含める:

```yaml
---
name: subagent-name
description: サブエージェントの簡潔な説明（1行）
tools: Tool1, Tool2, Tool3
---
```

## ファイル配置

```
codex/subagents/
├── content-acquirer.md         # Step 1
├── metadata-extractor.md       # Step 2
├── page-type-detector.md       # Step 2.5（既存）
├── overview-creator.md         # Step 3
├── minutes-referencer.md       # Step 4
├── material-selector.md        # Step 5
├── document-type-classifier.md # Step 6（既存）
├── pdf-converter.md            # Step 7
├── material-analyzer.md        # Step 8（既存）
├── summary-generator.md        # Step 9
└── file-writer.md              # Step 10
```

## サブエージェントの構成

各SKILL.mdは以下の構成で記述:

```markdown
---
name: subagent-name
description: ...
tools: ...
---

# <サブエージェント名>

## 目的
（簡潔な説明）

## 入力
（引数形式、JSON schema）

## 出力
（成功時のJSON、エラー時のJSON）

## 処理フロー
（ステップバイステップの処理内容）

## エラーコード
（エラーコード一覧と説明）

## 注意事項
（実装時の注意点）
```

## オーケストレータとの連携

### サブエージェントの呼び出し

オーケストレータ（base_workflow.md）は以下のようにサブエージェントを呼び出す:

```
Task(subagent_type: "content-acquirer", prompt: "...")
```

### データ受け渡し

- 前のステップの出力JSONを次のステップの入力に変換
- オーケストレータがデータ変換を担当

### 並列実行

以下のステップは並列実行可能:
- Step 6: document-type-classifier（複数PDF同時判定）
- Step 7: pdf-converter（複数PDF同時変換）
- Step 8: material-analyzer（複数資料同時分析）

オーケストレータが1つのメッセージで複数のTaskツールを呼び出す。

## 共通エラーコード

全サブエージェントで使用可能な共通エラーコード:

- `UNKNOWN_ERROR`: 不明なエラー（MAJOR）
- `TIMEOUT`: タイムアウト（MAJOR）
- `PERMISSION_DENIED`: 権限不足（CRITICAL）
- `FILE_NOT_FOUND`: ファイルが存在しない（MAJOR）
- `READ_FAILED`: 読み取り失敗（MAJOR）
- `WRITE_FAILED`: 書き込み失敗（CRITICAL）

## 実装チェックリスト

各サブエージェント実装時に以下を確認:

- [ ] YAML frontmatterが正しく設定されている
- [ ] 入力引数のフォーマットが明確
- [ ] JSON出力形式が標準に従っている
- [ ] 全エラーケースがJSON形式で返される
- [ ] JSON出力後に即座終了する
- [ ] エラーレベルが適切に設定されている

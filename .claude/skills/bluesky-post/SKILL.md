---
name: bluesky-post
description: レポートファイルからアブストラクトを抽出してBlueskyに投稿
allowed-tools:
  - Bash(awk:*)
  - Bash(cat:*)
  - Bash(ssky:*)
  - Read(path:./tmp/*)
  - Write(path:./tmp/*)
auto-execute: true
---

# bluesky-post

レポートファイル（`*_report.md`）からアブストラクトセクションを抽出し、Blueskyに投稿するサブエージェント。

## 用途

pagereportスキルのステップ11（Bluesky投稿）で使用されます。
また、手動でも`/bluesky-post`コマンドとして実行できます。

## 引数

```
<report_file_path>
```

- `report_file_path`: レポートファイルの絶対パスまたは相対パス（例: `./output/会議名_第8回_20251223_report.md`）

## Bash toolの使用制限

**【重要】Bash toolはシェルスクリプト実行のみに使用:**
- ファイル読み取り: Bash cat/head/tail **禁止** → **Read tool** を使用
- ファイル検索: Bash find/ls **禁止** → **Glob tool** を使用
- コンテンツ検索: Bash grep/rg **禁止** → **Grep tool** を使用
- ファイル編集: Bash sed/awk **禁止** → **Edit tool** を使用
- ファイル書き込み: Bash echo/cat **禁止** → **Write tool** を使用
- ユーザーへの通信: Bash echo **禁止** → 直接テキスト出力を使用
- 許可される使用: `.claude/skills/bluesky-post/post.sh` 実行、ssky、awk、その他システムコマンド

## 処理フロー

1. **アブストラクト抽出**: レポートファイルから`## アブストラクト`セクションのコードフェンス内のテキストを抽出
2. **Bluesky投稿**: sskyコマンドを使用してBlueskyに投稿（長文の場合は自動的にスレッド分割）

## 実装

実際の処理は同じディレクトリの`post.sh`スクリプトで実行されます。

```bash
bash .claude/skills/bluesky-post/post.sh "<report_file_path>"
```

## 出力

投稿が成功した場合、Blueskyの投稿URIが表示されます。

```
at://did:plc:xxxxx/app.bsky.feed.post/xxxxx
```

## エラーハンドリング

1. **sskyがインストールされていない**:
   - 警告メッセージを表示し、投稿をスキップ
   - レポート生成は正常に完了

2. **Blueskyにログインしていない**:
   - ログイン手順を案内する警告メッセージを表示
   - 投稿をスキップ

3. **投稿に失敗**:
   - エラーメッセージを表示
   - レポート生成は正常に完了

**重要**: Bluesky投稿は非クリティカルな処理です。投稿が失敗してもレポート生成を中断しません。

## 使用例

### pagereportスキル内での自動呼び出し

```bash
# Step 11: Bluesky投稿
bash .claude/skills/bluesky-post/post.sh "./output/日本成長戦略会議_第2回_20251224_report.md"
```

### 手動での呼び出し

```bash
/bluesky-post "output/電子処方箋等検討ワーキンググループ_第8回_20251223_report.md"
```

## 抽出ロジック

レポートファイルは以下の構造を持ちます：

```markdown
## アブストラクト

\`\`\`
ここにアブストラクト本文（1,000文字）
URLも含まれる
\`\`\`

## 資料一覧
...
```

抽出スクリプトは：
1. `## アブストラクト`行を検出
2. 次の\`\`\`（開始コードフェンス）をスキップ
3. 次の\`\`\`（終了コードフェンス）までの内容を抽出
4. 次の`## `セクションが現れたら終了

## Blueskyスレッド分割

sskyコマンドは自動的に長文をスレッドに分割します：
- 1投稿あたり300グラフェム制限
- 1,000文字のアブストラクトは通常4投稿のスレッドになる
- URLは最終投稿に含まれる

## 注意事項

- このスキルを使用する前に、`ssky login`でBlueskyにログインしておく必要があります
- ログインしていない場合は投稿をスキップしますが、エラーにはなりません
- 投稿内容はアブストラクトとURLのみで、詳細情報は含まれません

# 改善計画: skills/create-bot/SKILL.md

## 調査結果

### skill-creator の標準フォーマット

skill-creator (v1.5.1, https://github.com/gaubee/skill-creator) は Claude Code スキルの作成・管理ツール。
調査の結果、skill-creator が期待するスキルのフォーマットは以下の通り:

**ディレクトリ構造**:
```
.claude/skills/
└── package@version/
    ├── assets/references/
    │   ├── context7/      # Context7 から取得したドキュメント
    │   └── user/          # ユーザー提供のリファレンス
    ├── config.json        # 設定（Context7 ID, 検索エンジン等）
    └── SKILL.md           # スキル定義
```

**SKILL.md frontmatter の標準フィールド**（Claude Code 公式仕様に基づく）:

| フィールド | 説明 | 必須 |
|---|---|---|
| `name` | スキル識別子（小文字・ハイフン、最大64字） | ○ |
| `description` | 使用時期の説明（250字以内推奨、Claude の自動発動判断に使用） | ○ |
| `allowed-tools` | 許可ツール（スペース区切り） | 推奨 |
| `argument-hint` | 引数のヒント | 任意 |
| `disable-model-invocation` | `true` で手動トリガーのみ（副作用系に推奨） | 任意 |
| `user-invocable` | `false` で Claude のみ実行 | 任意 |
| `context` | `fork` でサブエージェント実行 | 任意 |
| `paths` | スキル発動対象ファイルのグロブパターン | 任意 |
| `model` | モデル指定（`inherit` 等） | 任意 |

**skill-creator の品質基準**:
- パッケージの設計哲学・解決する問題・基礎的な使い方を含む
- 附属ツールの利用方法の詳細説明
- 段階的プロセスの厳守（検索→情報取得→作成→統合）
- 500行以上の場合はリファレンスファイルに分離

### 現在の SKILL.md の評価

#### 良い点

1. **フロー構成が明確**: Phase 1〜6 の段階的なワークフローが分かりやすい
2. **手動介入ポイントの整理**: hCaptcha, 2FA, ログイン等の自動化不可能な箇所を明示
3. **技術的注意事項が充実**: Discord のカスタム UI やセレクタ安定性に関する知見が蓄積されている
4. **リファレンス分離**: selectors.md, error-patterns.md, portal-flow.md に詳細情報を適切に分離
5. **セキュリティ考慮**: トークン表示中のスクリーンショット禁止、`umask 077` による保存時パーミッション制限
6. **スクリプト一覧**: ファイルと役割の対応が明確
7. **出力の定義**: 何が出力されるかが明記されている

#### 改善が必要な点

1. **frontmatter のフィールド不足・非標準**:
   - `allowed-tools` が角括弧配列形式 `[Bash, Read, Write]` で記述されているが、Claude Code 標準はスペース区切り（例: `Bash Read Write`）
   - `disable-model-invocation` が未設定 — ブラウザ操作による副作用を伴うため `true` 推奨
   - `description` が長文（3行）で、Claude の自動発動トリガー判断に最適化されていない

2. **description のトリガー条件が frontmatter に埋もれている**:
   - `ユーザーが "Botを作って"... と言った場合にこのスキルを使用する` は有用だが、description 内に混在しておりパースしにくい
   - 機能説明とトリガー条件を分離すべき

3. **$ARGUMENTS の活用が未定義**:
   - `argument-hint` で `<bot-name> [--server <server-id>] [--token-file <path>]` を定義しているが、本文中で `$ARGUMENTS`, `$0`, `$1` をどう参照するかの説明がない

4. **クイックスタートとフロー説明の重複**:
   - 「クイックスタート（スクリプト実行）」と「操作フロー（スクリプト版）」が部分的に重複
   - スキルとして Claude が実行する際の手順と、人間が手動実行する際の手順が混在

5. **セマンティック判断ポイントの具体性不足**:
   - 「snapshot/screenshot で状態を見て判断すべき箇所」が3項目だけで、各 Phase でどのタイミングで判断すべきかが不明確

6. **エラーハンドリングの戦略が SKILL.md 本文に不在**:
   - `references/error-patterns.md` に詳細があるが、SKILL.md 本文ではフロー中の各フェーズでどのエラーをどう処理するかの指示がない
   - Claude がスキルを実行する際、リファレンスを参照するかどうかが不明確

7. **allowed-tools に不足がある可能性**:
   - cmux はBash経由で実行するため `Bash` は必須
   - `AskUserQuestion` が含まれていない — エスカレーション時に使用するはず
   - `Read` は snapshot/screenshot の結果を読むために必要

8. **スキル本文が147行で適正範囲だが、情報密度に偏りがある**:
   - 技術的注意事項（セレクタ、eval vs cmux click 等）が SKILL.md に詳細に書かれている一方、これらは `references/` にも重複して記載されている

## 改善項目

### 1. frontmatter の修正・拡充

**理由**: Claude Code の標準フォーマットに準拠させ、スキルの自動発動・権限制御を適切に行うため。

改善内容:
- `allowed-tools` を角括弧形式からスペース区切りに変更: `Bash Read Write AskUserQuestion`
- `disable-model-invocation: true` を追加（ブラウザ操作の副作用があるため、手動トリガーのみにする）
- `description` を250字以内に収め、トリガー条件を明確化

改善後の frontmatter 案:
```yaml
---
name: create-bot
description: >
  Discord Developer Portal で新しい Bot を作成する cmux ブラウザ自動化スキル。
  アプリ作成・Bot トークン取得・Intents 設定・招待URL生成を一連で実行。
  ユーザーが「Botを作って」「Discord Botを追加」「create discord bot」と言った場合に使用。
argument-hint: <bot-name> [--server <server-id>] [--token-file <path>]
allowed-tools: Bash Read Write AskUserQuestion
disable-model-invocation: true
---
```

### 2. $ARGUMENTS 参照の明示

**理由**: スキル呼び出し時の引数をどう処理するかが不明確だと、Claude が正しくパラメータを渡せない。

改善内容:
- 「クイックスタート」セクションの冒頭に、`$ARGUMENTS` からパラメータを抽出する手順を追加
- 例: `$0` = bot-name, `--server` → `$SERVER_ID`, `--token-file` → `$TOKEN_FILE`

### 3. 実行手順の Claude 向け最適化

**理由**: 現在の SKILL.md は「人間がスクリプトを実行する」視点と「Claude がスキルとして実行する」視点が混在している。Claude Code スキルとして最適化するため。

改善内容:
- 「クイックスタート」を「実行方法」に改名し、Claude がスキルとして実行する際のメインフローを記載
- 各 Phase に「成功判定」と「失敗時の対応」を明記
- リファレンスファイルの参照タイミングを明示（例: セレクタが見つからない場合 → `references/selectors.md` を確認）

### 4. セマンティック判断ポイントの各フェーズへの統合

**理由**: 独立セクションにまとめてあると、実行中にどのタイミングで確認すべきかが分かりにくい。

改善内容:
- 各 Phase 内に「確認ポイント」として統合
- 例: Phase 2 内に「snapshot で CAPTCHA/エラーメッセージの有無を確認」を記載

### 5. エラーハンドリング指示の統合

**理由**: エラー対応が `references/error-patterns.md` にしかないと、Claude がスキル実行中に参照しない可能性がある。

改善内容:
- 各 Phase に「エラー時」サブセクションを追加し、主要なエラーパターンと対処を簡潔に記載
- 詳細は「詳細は `references/error-patterns.md` を参照」とリンク

### 6. 技術的注意事項の重複解消

**理由**: SKILL.md の「技術的な注意事項」セクションと `references/selectors.md` の冒頭注意事項が重複している。

改善内容:
- SKILL.md の技術的注意事項は要約（3〜5行）に留め、詳細はリファレンスへのリンクで誘導
- SKILL.md 本文の行数を削減し、フロー情報の密度を上げる

### 7. AskUserQuestion によるエスカレーションパターンの明記

**理由**: 現在は `say` コマンドでの通知のみ記載されているが、Claude Code スキルとして実行する場合は `AskUserQuestion` ツールの方が適切。

改善内容:
- エスカレーション時に `AskUserQuestion` を使い、ユーザーに「完了しましたか？」と確認するパターンを追加
- `say` コマンドはスクリプト内での通知用に残す

## 実装方針

### ステップ 1: frontmatter の修正
- `allowed-tools` フォーマット修正
- `disable-model-invocation: true` 追加
- `description` リライト

### ステップ 2: 構造リファクタリング
- 「クイックスタート」→「実行方法」へ改名、$ARGUMENTS 参照を追加
- 各 Phase に「成功判定」「エラー時」「確認ポイント」サブセクションを統合
- 「セマンティック判断ポイント」独立セクションを削除（各 Phase へ統合済み）

### ステップ 3: 重複解消と簡略化
- 「技術的な注意事項」を要約に圧縮、詳細はリファレンスへリンク
- フロー説明の重複を排除

### ステップ 4: エスカレーションパターンの更新
- `AskUserQuestion` パターンの追加
- 手動介入ポイント表に対処方法を追加

### 注意事項
- `references/` 配下のファイルは今回の改善対象外（SKILL.md のみ）
- スクリプトファイル自体の変更は行わない
- 現在の良い点（Phase 構成、セキュリティ考慮、リファレンス分離）は維持する
- 改善後の SKILL.md は 120〜150 行程度を目標とする

# discord-portal-cli 公開準備 実装計画書

## 1. 概要

discord-portal-cli を Claude Code プラグインとして公開可能な状態にする。参考リポジトリ `using-cmux`（既に公開済み）の構造に合わせ、マーケットプレイス対応・README整備・インストーラ作成・コマンド定義を行う。

**現在の状態**: コア機能（create-bot スキル）は完成済み。公開に必要なメタデータ・ドキュメント・配布手段が不足。

**ゴール**: `/plugin marketplace add yamamoto/discord-portal-cli` でインストール可能な状態にする。

---

## 2. 変更一覧

| # | 変更 | 種別 | ファイル |
|---|------|------|---------|
| 1 | marketplace.json 作成 | 新規 | `.claude-plugin/marketplace.json` |
| 2 | plugin.json 更新 | 修正 | `.claude-plugin/plugin.json` |
| 3 | SKILL.md 品質向上 | 修正 | `skills/create-bot/SKILL.md` |
| 4 | README.md 英語版リライト | 修正 | `README.md` |
| 5 | README.ja.md 日本語版作成 | 新規 | `README.ja.md` |
| 6 | install.sh 作成 | 新規 | `install.sh` |
| 7 | commands/create-bot.md 作成 | 新規 | `commands/create-bot.md` |
| 8 | docs/seeds/ 整理 | 修正 | `.gitignore` |

---

## 3. ファイル別の具体的な内容

### 3.1 `.claude-plugin/marketplace.json`（新規作成）

参考: `~/git/using-cmux/.claude-plugin/marketplace.json`

```json
{
  "name": "yamamoto-discord-portal-cli",
  "owner": {
    "name": "yamamoto",
    "email": "github@yamamoto"
  },
  "plugins": [
    {
      "name": "discord-portal-cli",
      "source": "./",
      "description": "Automate Discord Developer Portal operations (create bots, configure permissions, etc.) via cmux browser automation",
      "version": "0.1.0",
      "author": {
        "name": "yamamoto"
      },
      "repository": "https://github.com/yamamoto/discord-portal-cli",
      "license": "MIT",
      "keywords": ["claude-skill", "discord", "bot", "automation", "cmux", "browser"],
      "category": "automation",
      "tags": ["discord", "bot", "browser-automation", "cmux"]
    }
  ]
}
```

**判断**: `category` は `"automation"` を推奨。`"browser"` カテゴリは一般的でなく、このプラグインの本質は Discord 操作の自動化である。

**注意**: `repository` の URL はリポジトリ公開時に実際の GitHub URL に差し替える。`owner.email` も実際のものに要調整。

---

### 3.2 `.claude-plugin/plugin.json`（更新）

参考: `~/git/using-cmux/.claude-plugin/plugin.json`

現在の内容に以下を追加:
- `repository` フィールド
- `hooks.SessionStart` — cmux 環境でのタブ名変更（using-cmux と同等）

```json
{
  "name": "discord-portal-cli",
  "version": "0.1.0",
  "description": "Automate Discord Developer Portal operations (create bots, configure permissions, etc.) via cmux browser automation",
  "author": {
    "name": "yamamoto"
  },
  "license": "MIT",
  "repository": "https://github.com/yamamoto/discord-portal-cli",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$CMUX_SURFACE_ID\" ] && [ -z \"$CMUX_NO_RENAME_TAB\" ]; then REF=$(cmux identify | jq -r '.caller.surface_ref'); NUM=$(echo \"$REF\" | cut -d: -f2); cmux rename-tab --surface \"$REF\" \"[$NUM] Claude Code\"; fi"
          }
        ]
      }
    ]
  }
}
```

**判断**: SessionStart フックは using-cmux と同一のものを採用。discord-portal-cli は cmux browser を前提とするため、cmux 内動作時のタブリネームは同様に有用。ただし using-cmux を同時にインストールしている場合は重複するため、`CMUX_NO_RENAME_TAB` 環境変数で制御できる設計になっている。

---

### 3.3 `skills/create-bot/SKILL.md`（品質向上）

参考: `~/git/using-cmux/skills/using-cmux/SKILL.md` のフォーマット・構造

現在の SKILL.md（147行）は内容として十分だが、以下の改善を行う:

#### 3.3.1 フロントマターの簡素化

現在:
```yaml
---
name: create-bot
description: >
  Discord Developer Portal で新しいBotアプリケーションを作成する。
  cmux ブラウザ自動化を使い、アプリケーション作成 → Bot有効化 → トークン取得 → 権限設定 → 招待URL生成を一連で行う。
  ユーザーが "Botを作って", "Discord Botを追加", "create discord bot", "新しいBotが必要" と言った場合にこのスキルを使用する。
argument-hint: <bot-name> [--server <server-id>] [--token-file <path>]
allowed-tools: [Bash, Read, Write]
---
```

変更後（using-cmux 形式に合わせて簡素化）:
```yaml
---
name: create-bot
description: "Discord Developer Portal で Bot を作成する。cmux ブラウザ自動化でアプリケーション作成・トークン取得・権限設定・招待URL生成を行う。"
---
```

**理由**: using-cmux は `name` と `description` のみのシンプルなフロントマター。`argument-hint` や `allowed-tools` は plugin.json 側で管理されるべき情報。ただし、現状 `argument-hint` がスキル呼び出しの UX に貢献している場合は残す選択肢もある。

→ **推奨**: `argument-hint` は残す（ユーザーが `/create-bot` 呼び出し時の引数ヒントとして有用）。`allowed-tools` は削除（plugin.json レベルで管理）。

#### 3.3.2 cmux browser コマンドリファレンスセクションの追加

using-cmux の SKILL.md はブラウザ操作セクション（約120行）で cmux browser のコマンドを網羅的にカバーしている。discord-portal-cli の SKILL.md にも、**使用するコマンドに絞った**リファレンスセクションを追加する。

追加内容:

```markdown
## cmux browser コマンドリファレンス

本スキルで使用する cmux browser の主要コマンド。

### ブラウザ操作

| 操作 | コマンド |
|------|---------|
| ブラウザ起動 | `cmux browser open "URL"` |
| ページ遷移 | `cmux browser $SURFACE goto "URL"` |
| 読み込み待ち | `cmux browser $SURFACE wait --load-state complete --timeout 15` |
| スクリーンショット | `cmux browser $SURFACE screenshot --out /tmp/file.png` |
| スナップショット | `cmux browser $SURFACE snapshot --interactive` |

### 要素操作

| 操作 | コマンド |
|------|---------|
| クリック | `cmux browser $SURFACE click --selector "SELECTOR"` |
| テキスト入力 | `cmux browser $SURFACE fill --selector "SELECTOR" --value "TEXT"` |
| JS実行 | `cmux browser $SURFACE eval "SCRIPT"` |
| URL取得 | `cmux browser $SURFACE get url` |

### Discord UI 操作パターン

Discord のカスタム UI 操作の定番パターンをまとめる:

**テキストベースのボタンクリック**:
```bash
cmux browser $SURFACE eval "
  var btn = Array.from(document.querySelectorAll('button')).find(function(b) {
    return b.textContent.trim() === 'ターゲットテキスト';
  });
  if (btn) btn.setAttribute('data-auto-click', '1');
"
cmux browser $SURFACE click --selector "[data-auto-click]"
```

**チェックボックスの操作**（Discord カスタム UI 対応）:
```bash
cmux browser $SURFACE eval "
  var cb = document.querySelectorAll('input[type=checkbox]')[INDEX];
  if (cb && !cb.checked) cb.setAttribute('data-auto-cb', '1');
"
cmux browser $SURFACE click --selector "[data-auto-cb]"
```
```

#### 3.3.3 構造の整理

現在のセクション構成は維持しつつ、以下を調整:
- 「セマンティック判断ポイント」セクションを「技術的な注意事項」に統合
- 「出力」セクションをフロー説明の直後に移動（ユーザーが期待する結果を早めに提示）
- using-cmux の「よくある間違い」テーブル形式を参考に、エラーパターンの要約テーブルを追加

#### 3.3.4 エラーハンドリング強化

references/error-patterns.md の内容を SKILL.md 内に要約テーブルとして組み込む:

```markdown
## よくある問題と対処

| 症状 | 原因 | 対処 |
|------|------|------|
| hCaptcha 出現 | Bot作成の検証 | ユーザーにエスカレーション |
| 2FA パスワード要求 | トークンリセット時のセキュリティ | ユーザーにエスカレーション |
| /login にリダイレクト | セッション切れ | ユーザーにログインを依頼 |
| セレクタ不一致 | Discord のデプロイ更新 | snapshot で確認し、テキストベース検索に切り替え |
| 保存ボタンが無効 | 変更なし | スキップして次の Phase へ |
```

---

### 3.4 `README.md`（英語版リライト）

参考: `~/git/using-cmux/README.md`（114行）の構造

現在の README.md を以下の構造にリライト:

```markdown
**[日本語](README.ja.md)** | English

# discord-portal-cli

A Claude Code plugin that automates Discord Developer Portal operations via cmux browser automation.

## Motivation

- Discord has no CLI or API for managing Developer Portal resources
- Creating bots requires manual browser navigation
- When you need multiple bots, the manual process is significant friction
- cmux browser automation eliminates this by driving the real browser session

## What's Included

| Category | Description |
|----------|-------------|
| **Bot creation** | Full lifecycle: application → token → intents → OAuth2 URL |
| **Error handling** | CAPTCHA detection, 2FA escalation, login checks |
| **Token security** | Clipboard-based retrieval, no screenshots during display |
| **Semantic approach** | Claude reads SKILL.md, executes scripts, verifies via screenshots |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [cmux](https://cmux.dev) installed, with Claude Code running inside a cmux session
- A browser session logged into [Discord Developer Portal](https://discord.com/developers/applications)
- macOS (uses `pbpaste` for clipboard access)

## Installation

### Option 1: Plugin (recommended)

```
/plugin marketplace add yamamoto/discord-portal-cli
/plugin install discord-portal-cli
```

Skills, commands, and hooks are installed together.

**To update:**

```
/plugin update discord-portal-cli
/reload-plugins
```

### Option 2: Agent Skills (skills only)

```bash
npx skills add yamamoto/discord-portal-cli
```

> Note: Commands (`/create-bot`) are not included in Agent Skills distribution.

### Option 3: Manual (legacy)

```bash
git clone https://github.com/yamamoto/discord-portal-cli.git
cd discord-portal-cli
bash install.sh
```

Installed files:

| Destination | Contents |
|-------------|----------|
| `~/.claude/skills/create-bot/SKILL.md` | Main skill definition |
| `~/.claude/commands/create-bot.md` | `/create-bot` slash command |

### Verify Installation (manual only)

```bash
bash install.sh --check
```

### Uninstall (manual only)

```bash
bash install.sh --uninstall
```

## Usage

```
/create-bot MyBotName
/create-bot MyBotName --server 123456789
```

Claude will:
1. Open the Discord Developer Portal in a cmux browser pane
2. Create the application and retrieve the bot token
3. Configure privileged gateway intents
4. Generate an OAuth2 invite URL
5. (Optional) Invite the bot to a specified server

**Human intervention required for**: hCaptcha, 2FA password, login, server authorization.

## License

[MIT](LICENSE)
```

**注意**: `repository` URL は公開時に実際のものに差し替え。バナー画像は不要（指示通り）。

---

### 3.5 `README.ja.md`（新規作成）

参考: `~/git/using-cmux/README.ja.md`（115行）

README.md と同じ構造を日本語で記述。冒頭のリンクは以下:

```markdown
日本語 | **[English](README.md)**
```

内容は README.md の日本語訳。既存の README.md の「Why」セクションや architecture.md の記述を活用。

---

### 3.6 `install.sh`（新規作成）

参考: `~/git/using-cmux/install.sh`（285行）

discord-portal-cli のインストール対象:

| ソース | インストール先 |
|--------|---------------|
| `skills/create-bot/SKILL.md` | `~/.claude/skills/create-bot/SKILL.md` |
| `commands/create-bot.md` | `~/.claude/commands/create-bot.md` |

**判断: scripts/ と references/ はインストールに含めるか？**

→ **推奨: 含めない**。理由:
- SKILL.md がスクリプトを `skills/create-bot/scripts/` の相対パスで参照している
- プラグインインストール時はリポジトリ全体がインストールされるため、スクリプトはリポジトリ内から実行可能
- 手動インストール（install.sh）の場合、SKILL.md 内のスクリプトパスが壊れるため、スクリプトも含めるか **SKILL.md 内のパスを絶対パスに変更する必要がある**

→ **代替案**: install.sh でリポジトリのクローン先パスを記録し、SKILL.md 内のスクリプトパスをインストール時に書き換える。しかし複雑になるため、**手動インストール時はリポジトリディレクトリからの実行を前提とし、install.sh は SKILL.md と commands のみをコピーする**方針とする。SKILL.md にはリポジトリパスを示す注意書きを追加。

実装内容:
- `set -euo pipefail`
- ソースディレクトリの解決（`SCRIPT_DIR`）
- ソース/デスティネーションのマッピング（2ファイル）
- `check_source_files()` — ソースファイルの存在確認
- `do_check()` — `--check` モード
- `do_uninstall()` — `--uninstall` モード（空ディレクトリ削除含む）
- `do_install()` — インストール実行（既存ファイル警告 + コピー）
- カラー出力（`green()`, `yellow()`, `red()`）
- `--help` モード
- メッセージは日本語

---

### 3.7 `commands/create-bot.md`（新規作成）

参考: `~/git/using-cmux/commands/cmux.md`（69行）

`/create-bot` スラッシュコマンドのクイックリファレンス。

```markdown
# Discord Bot 作成

Discord Developer Portal で Bot を作成する。

## 使い方

```
/create-bot <BOT_NAME> [--server <SERVER_ID>] [--token-file <PATH>]
```

## 作成フロー

| Phase | 内容 | 手動介入 |
|-------|------|---------|
| 1 | ブラウザ起動 + ログイン確認 | ログイン切れ時 |
| 2 | アプリケーション作成 | hCaptcha |
| 3 | Bot トークン取得 | 2FA |
| 4 | Privileged Intents 設定 | — |
| 5 | OAuth2 招待URL生成 | — |
| 6 | サーバー招待（--server 時） | Authorize |

## 出力

- Bot Token（文字数のみ表示。安全に保管すること）
- Application ID
- 招待URL

## 注意事項

- Discord Developer Portal にログイン済みのブラウザセッションが必要
- hCaptcha や 2FA が出た場合はユーザーがブラウザで操作する必要あり
- トークン取得中のスクリーンショットは**実行しない**（セキュリティ）

詳細は create-bot スキル（SKILL.md）を参照してください。
```

---

### 3.8 `docs/seeds/` の整理

参考: using-cmux には `docs/` ディレクトリは存在しない

**判断**: `docs/seeds/architecture.md` は開発時の設計ドキュメント。公開リポジトリに含めても害はないが、`docs/seeds/` というディレクトリ名は内部用の印象。

→ **推奨**: そのまま残す。`.gitignore` に追加する必要はない（機密情報を含まず、プロジェクトの設計意図が分かるドキュメントとして有用）。ディレクトリ名の変更も不要（実害なし、変更の ROI が低い）。

---

### 3.9 `.gitignore` 更新

using-cmux に合わせて `.team/` 関連の除外を追加:

```gitignore
# Secrets
.envrc

# Claude Code local state
.config/
.claude/settings.local.json

# OS
.DS_Store

# Node
node_modules/

# Team ephemeral directories
.team/output/
.team/prompts/
.team/docs-snapshot/
```

---

## 4. 実装順序

依存関係を考慮した実装順。同時に着手可能なものはグループ化。

### Step 1: メタデータ（並行可能）
1. **`.claude-plugin/marketplace.json`** — 新規作成
2. **`.claude-plugin/plugin.json`** — repository + hooks 追加

理由: 他のファイルへの依存なし。マーケットプレイス公開の最低要件。

### Step 2: コマンド定義
3. **`commands/create-bot.md`** — 新規作成

理由: SKILL.md 改修前に作成し、SKILL.md から参照関係を確認。

### Step 3: SKILL.md 品質向上
4. **`skills/create-bot/SKILL.md`** — フロントマター簡素化 + cmux browser リファレンス追加 + 構造整理

理由: コマンドとスキルの整合性を確認しながら作業。

### Step 4: ドキュメント整備（並行可能）
5. **`README.md`** — 英語版リライト
6. **`README.ja.md`** — 日本語版新規作成

理由: SKILL.md の内容が確定した後にドキュメントを整備。

### Step 5: インストーラ + 雑務
7. **`install.sh`** — 新規作成
8. **`.gitignore`** — .team/ 追加

理由: 最終成果物が確定した後にインストール対象を定義。

---

## 5. 判断事項

### 5.1 SKILL.md フロントマターの `argument-hint`

| 選択肢 | メリット | デメリット |
|---------|---------|-----------|
| **残す（推奨）** | `/create-bot` 呼び出し時に引数ヒントが表示される | using-cmux との形式不統一 |
| 削除する | using-cmux と完全に形式統一 | ユーザー体験の低下 |

**推奨**: `argument-hint` は残す。`allowed-tools` は削除。

### 5.2 install.sh のスクリプト同梱

| 選択肢 | メリット | デメリット |
|---------|---------|-----------|
| SKILL.md + command のみ（推奨） | シンプル。プラグインインストールでは不要 | 手動インストールでスクリプトが動かない |
| scripts/ + references/ も同梱 | 手動でも完全動作 | パスの書き換えが必要。複雑 |

**推奨**: SKILL.md + command のみ。手動インストールは「リポジトリクローン＋install.sh」の形で、スクリプトはクローンしたリポジトリ内から参照される前提。

### 5.3 category の選択

| 選択肢 | 理由 |
|---------|------|
| **`automation`（推奨）** | プラグインの本質が「Discord Developer Portal 操作の自動化」 |
| `browser` | cmux browser を使うが、ブラウザツール全般ではない |
| `terminal` | using-cmux の category だが、discord-portal-cli はターミナル操作全般ではない |

### 5.4 repository URL

現時点では仮の URL（`https://github.com/yamamoto/discord-portal-cli`）を設定。実際の GitHub リポジトリ作成時に差し替える。marketplace.json と plugin.json の両方で統一すること。

### 5.5 docs/seeds/ の扱い

**推奨**: そのまま残す。開発経緯を示すドキュメントとして有用。`.gitignore` への追加は不要。

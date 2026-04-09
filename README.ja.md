日本語 | **[English](README.md)**

# discord-portal-cli

Discord Developer Portal の操作を cmux ブラウザ自動化で行う Claude Code プラグイン。

## モチベーション

- Discord には Developer Portal リソース（アプリケーション、Bot）を管理する CLI や API がない
- Bot 作成には毎回ブラウザでの手動操作が必要
- 複数の Bot が必要な場合、手動操作の負担は大きい
- cmux ブラウザ自動化により、実際のブラウザセッションを操作してこの負担を解消する

## 概要

| カテゴリ | 内容 |
|---------|------|
| **Bot 作成** | アプリケーション → トークン → Intents → OAuth2 URL の一連のフロー |
| **エラーハンドリング** | CAPTCHA 検出、2FA エスカレーション、ログイン確認 |
| **トークンセキュリティ** | クリップボード経由で取得、トークン表示中のスクリーンショット禁止 |
| **セマンティックアプローチ** | Claude が SKILL.md を読み、スクリプトを実行し、スクリーンショットで結果を検証 |

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであること
- [cmux](https://cmux.dev) がインストール済みで、cmux セッション内で Claude Code を実行すること
- [Discord Developer Portal](https://discord.com/developers/applications) にログイン済みのブラウザセッションがあること
- macOS 環境（クリップボード取得に `pbpaste` を使用）

## インストール

### 方法1: Plugin（推奨）

```
/plugin marketplace add yamamoto/discord-portal-cli
/plugin install discord-portal-cli
```

スキル・コマンド・フックがまとめてインストールされる。

**アップデート:**

```
/plugin update discord-portal-cli
/reload-plugins
```

### 方法2: Agent Skills（スキルのみ）

```bash
npx skills add yamamoto/discord-portal-cli
```

> 注: Agent Skills ではコマンド（`/create-bot`）は含まれない。

### 方法3: 手動（レガシー）

```bash
git clone https://github.com/yamamoto/discord-portal-cli.git
cd discord-portal-cli
bash install.sh
```

以下のファイルがインストールされる:

| インストール先 | 内容 |
|---------------|------|
| `~/.claude/skills/create-bot/SKILL.md` | メインスキル定義 |
| `~/.claude/commands/create-bot.md` | `/create-bot` スラッシュコマンド |

### インストール確認（手動のみ）

```bash
bash install.sh --check
```

### アンインストール（手動のみ）

```bash
bash install.sh --uninstall
```

## 使い方

```
/create-bot MyBotName
/create-bot MyBotName --server 123456789
```

Claude が以下を実行する:
1. cmux ブラウザペインで Discord Developer Portal を開く
2. アプリケーションを作成し、Bot トークンを取得
3. Privileged Gateway Intents を設定
4. OAuth2 招待URLを生成
5. （オプション）指定したサーバーに Bot を招待

**人間の介入が必要な場面**: hCaptcha、2FA パスワード、ログイン、サーバー認可。

## ライセンス

[MIT](LICENSE)

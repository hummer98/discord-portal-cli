---
name: create-bot
description: >
  Discord Developer Portal で新しいBotアプリケーションを作成する。
  cmux ブラウザ自動化を使い、アプリケーション作成 → Bot有効化 → トークン取得 → 権限設定 → 招待URL生成を一連で行う。
  ユーザーが "Botを作って", "Discord Botを追加", "create discord bot", "新しいBotが必要" と言った場合にこのスキルを使用する。
argument-hint: <bot-name> [--server <server-id>]
allowed-tools: [Bash, Read, Write]
---

# Discord Bot 作成スキル

cmux ブラウザ自動化で Discord Developer Portal を操作し、Bot を作成する。

## 前提条件

- cmux がインストール済み
- Discord Developer Portal にログイン済みのブラウザセッションがある
- cmux でブラウザペインを操作可能

## 操作フロー

### Phase 1: アプリケーション作成

1. Discord Developer Portal (`https://discord.com/developers/applications`) を開く
2. "New Application" ボタンをクリック
3. アプリケーション名を入力
4. ToS同意チェック → "Create"

### Phase 2: Bot 有効化

1. 左サイドバー "Bot" をクリック
2. "Add Bot" → "Yes, do it!"（※ 最近のUIでは自動作成されている場合あり）
3. "Reset Token" → トークンをコピー
4. Privileged Gateway Intents を設定:
   - MESSAGE CONTENT INTENT: ON（メッセージ内容の読み取りが必要な場合）
   - SERVER MEMBERS INTENT: ON（メンバー一覧が必要な場合）
   - PRESENCE INTENT: ON（プレゼンス情報が必要な場合）

### Phase 3: OAuth2 / 招待URL生成

1. 左サイドバー "OAuth2" → "URL Generator"
2. Scopes: `bot`, `applications.commands`
3. Bot Permissions: 用途に応じて選択
   - 録音Bot: `Connect`, `Speak`, `Use Voice Activity`
   - 汎用Bot: `Send Messages`, `Read Message History`, `Connect`, `Speak`
4. 生成された招待URLをコピー

### Phase 4: サーバーへの招待（オプション）

1. 招待URLをブラウザで開く
2. 対象サーバーを選択
3. 権限を確認 → "Authorize"

## 出力

- Bot Token（安全に保管すること）
- Application ID
- 招待URL
- 設定した権限の一覧

## TODO（実装予定）

- [ ] cmux コマンドシーケンスの具体的な実装
- [ ] ブラウザ操作の各ステップで要素セレクタを特定
- [ ] エラーケースの対応（名前重複、レート制限等）
- [ ] トークンの安全な受け渡し方法

---
name: create-bot
description: >
  Discord Developer Portal で新しいBotアプリケーションを作成する。
  cmux ブラウザ自動化を使い、アプリケーション作成 → Bot有効化 → トークン取得 → 権限設定 → 招待URL生成を一連で行う。
  ユーザーが "Botを作って", "Discord Botを追加", "create discord bot", "新しいBotが必要" と言った場合にこのスキルを使用する。
argument-hint: <bot-name> [--server <server-id>] [--token-file <path>]
allowed-tools: [Bash, Read, Write]
---

# Discord Bot 作成スキル

cmux ブラウザ自動化で Discord Developer Portal を操作し、Bot を作成する。

## 前提条件

- cmux がインストール済み
- Discord Developer Portal にログイン済みのブラウザセッションがある
- macOS 環境（クリップボード取得に `pbpaste` を使用）

## クイックスタート（スクリプト実行）

```bash
# 基本実行
bash skills/create-bot/scripts/create-bot-main.sh "MyBot"

# サーバーへの招待も行う場合
bash skills/create-bot/scripts/create-bot-main.sh "MyBot" --server <SERVER_ID>

# トークンをファイルに保存する場合
bash skills/create-bot/scripts/create-bot-main.sh "MyBot" --token-file /tmp/bot-token.txt
```

## 操作フロー（スクリプト版）

### Phase 1: ブラウザ起動 + ログイン確認
`scripts/open-portal.sh`
- cmux browser でブラウザペインを開く
- Discord Developer Portal のログイン状態を確認
- 未ログインの場合はユーザーにエスカレーション

### Phase 2: アプリケーション作成
`scripts/create-application.sh $BOT_NAME`
- 「新しいアプリケーション」ボタンをクリック
- 名前入力 → ToS同意 → 作成
- **CAPTCHA**: 高確率で hCaptcha が出現 → ユーザーにエスカレーション
- 出力: Application ID

### Phase 3: Bot トークン取得
`scripts/get-bot-token.sh $APP_ID`
- Bot ページで「トークンをリセット」→ 確認ダイアログ
- **2FA**: パスワード入力が要求される → ユーザーにエスカレーション
- コピーボタン → クリップボード(`pbpaste`) でトークン取得
- **⚠️ セキュリティ**: トークン表示中に snapshot/screenshot は絶対に実行しない
- 出力: Bot Token（文字数のみ通知）

### Phase 4: Privileged Gateway Intents 設定
`scripts/configure-intents.sh $APP_ID`
- Presence Intent / Server Members Intent / Message Content Intent を有効化
- 「変更を保存」で設定を保存

### Phase 5: OAuth2 招待URL生成
`scripts/generate-invite-url.sh $APP_ID`
- スコープ: `bot`, `applications.commands`
- 権限: `メッセージを送る`, `メッセージ履歴を読む`, `接続`, `発言`
- 出力: 招待URL

### Phase 6: サーバー招待（--server 指定時のみ）
`scripts/invite-to-server.sh $INVITE_URL $SERVER_ID`
- 招待URLをブラウザで開く → サーバー選択 → Authorize
- CAPTCHA が出る場合あり → ユーザーにエスカレーション

## 手動介入ポイント

以下の状況では自動化が不可能で、ユーザーによるブラウザ操作が必要:

| ポイント | Phase | 検出方法 |
|---|---|---|
| hCaptcha | 2 (アプリ作成) | `iframe[src*=hcaptcha]` or 「人間ですよね？」テキスト |
| 2FA | 3 (トークンリセット) | `input[type=password]` |
| ログイン | 1 (ポータルアクセス) | URL が `/login` にリダイレクト |
| サーバー招待の Authorize | 6 | 複雑な UI のため |

エスカレーション: `say "⚠️ 人間の介入が必要です: <問題の説明>"` コマンドで通知。

## セマンティック判断ポイント

Claude が snapshot/screenshot で状態を見て判断すべき箇所:
- モーダルダイアログの内容確認（エラーメッセージの有無）
- 保存成功メッセージの確認
- DOM 構造が変わった場合のセレクタ再特定

## 技術的な注意事項

### Discord のカスタム UI
- `check`/`uncheck` コマンドは効かない → **`click` を使用**
- React 管理の状態は `eval "element.click()"` で更新されないことがある
- **推奨パターン**: `eval` で `data-*` 属性を付与 → `cmux browser click --selector "[data-*]"` で操作

### セレクタの安定性
- クラス名にハッシュ（`button_a22cb0` 等）が含まれ、デプロイごとに変更される
- 安定するセレクタ: `input#appname`, `input#bot-username-input`, `input[type=checkbox]`
- 不安定なセレクタ: `.primary_a22cb0`, `.button_a22cb0`
- テキストベース検索が最も安定: `Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === 'ターゲットテキスト')`

### Bot は自動生成
- 2024年以降、アプリケーション作成時に Bot が自動で追加される
- 「Add Bot」→「Yes, do it!」のフローは **不要**
- Bot ページには初回から Bot 情報が表示されている

### トークンのセキュリティ
- 取得方法: コピーボタンクリック → `pbpaste`（macOS クリップボード）
- フォールバック: テキストノードから直接取得（eval 経由）
- 取得後は即座にページ遷移してトークン表示を閉じる
- ファイル保存時は `umask 077` でパーミッション制限

### 日本語 UI
- ボタンテキストは日本語: 「新しいアプリケーション」「作成」「変更を保存」「トークンをリセット」「実行します！」
- ロケール依存のため、英語 UI では動作しない可能性あり

## スクリプト一覧

| ファイル | 役割 |
|---|---|
| `scripts/create-bot-main.sh` | メインオーケストレータ |
| `scripts/open-portal.sh` | ブラウザ起動 + ログイン確認 |
| `scripts/create-application.sh` | アプリケーション作成 |
| `scripts/get-bot-token.sh` | Bot トークン取得 |
| `scripts/configure-intents.sh` | Privileged Intents 設定 |
| `scripts/generate-invite-url.sh` | OAuth2 招待URL生成 |
| `scripts/invite-to-server.sh` | サーバー招待（オプション） |
| `scripts/helpers/safe-click.sh` | 安全なクリック関数群 |
| `scripts/helpers/check-login.sh` | ログイン確認ヘルパー |

## リファレンス

- [`references/selectors.md`](references/selectors.md) — 検証済みセレクタ一覧
- [`references/error-patterns.md`](references/error-patterns.md) — エラーパターンと対処法
- [`references/portal-flow.md`](references/portal-flow.md) — Developer Portal URL・UI 構造

## 出力

- Bot Token（安全に保管すること — 文字数のみ通知）
- Application ID
- 招待URL
- 設定した権限の一覧

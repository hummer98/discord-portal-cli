---
name: create-bot
description: "Discord Developer Portal で Bot を作成する。cmux ブラウザ自動化でアプリケーション作成・トークン取得・権限設定・招待URL生成を行う。"
argument-hint: <bot-name> [--server <server-id>] [--token-file <path>]
---

# Discord Bot 作成スキル

cmux ブラウザ自動化で Discord Developer Portal を操作し、Bot を作成する。

> **インストール方法**: プラグインインストール（`/plugin install discord-portal-cli`）を推奨。手動インストール（`install.sh`）の場合、スクリプトの実行にはリポジトリルートからの実行が前提となる。

## 前提条件

- cmux がインストール済み
- Discord Developer Portal にログイン済みのブラウザセッションがある
- macOS 環境（クリップボード取得に `pbpaste` を使用）

## パラメータ抽出

`$ARGUMENTS` から以下を抽出する:

```
BOT_NAME="$1"           # 必須: Bot名
SERVER_ID=""             # --server <id> が指定された場合
TOKEN_FILE=""            # --token-file <path> が指定された場合
```

`BOT_NAME` が未指定の場合は `AskUserQuestion` で Bot 名を尋ねる。

## 出力

- Bot Token（安全に保管すること — 文字数のみ通知）
- Application ID
- 招待URL
- 設定した権限の一覧

## 操作フロー（スクリプト版）

### Phase 1: ブラウザ起動 + ログイン確認

`scripts/open-portal.sh`

- cmux browser でブラウザペインを開く
- Discord Developer Portal のログイン状態を確認
- **成功判定**: URL が `discord.com/developers/applications` を含む
- **確認ポイント**: snapshot でページ内容を確認し、ログイン済みかを判断
- **エラー時**: URL が `/login` にリダイレクト → `AskUserQuestion` でログインを依頼。詳細は [error-patterns.md](references/error-patterns.md) 参照

### Phase 2: アプリケーション作成

`scripts/create-application.sh $BOT_NAME`

- 「新しいアプリケーション」ボタンをクリック → 名前入力 → ToS同意 → 作成
- **成功判定**: アプリケーション設定ページに遷移し、Application ID が取得できる
- **確認ポイント**: モーダルダイアログの内容確認（エラーメッセージの有無）
- **エラー時**:
  - hCaptcha 出現（`iframe[src*=hcaptcha]` で検出）→ `AskUserQuestion` で CAPTCHA 解決を依頼
  - 名前重複エラー → 別名を `AskUserQuestion` で確認
- 出力: Application ID

### Phase 3: Bot トークン取得

`scripts/get-bot-token.sh $APP_ID`

- Bot ページで「トークンをリセット」→ 確認ダイアログ → コピーボタン → `pbpaste` で取得
- **⚠️ セキュリティ**: トークン表示中に snapshot/screenshot は絶対に実行しない
- **成功判定**: `pbpaste` で取得した文字列がトークン形式（`.` 区切り3パート）に合致
- **確認ポイント**: リセット確認ダイアログが表示されたことを確認
- **エラー時**:
  - 2FA パスワード要求（`input[type=password]` で検出）→ `AskUserQuestion` でパスワード入力を依頼
  - コピー失敗 → eval 経由のフォールバック取得を試行
- 出力: Bot Token（文字数のみ通知。`--token-file` 指定時は `umask 077` で保存）

### Phase 4: Privileged Gateway Intents 設定

`scripts/configure-intents.sh $APP_ID`

- Presence Intent / Server Members Intent / Message Content Intent を有効化
- **成功判定**: 「変更を保存」後に保存成功メッセージが表示される
- **確認ポイント**: snapshot で各トグルの状態と保存成功メッセージを確認
- **エラー時**: 保存失敗 → ページリロード後にリトライ。詳細は [error-patterns.md](references/error-patterns.md) 参照

### Phase 5: OAuth2 招待URL生成

`scripts/generate-invite-url.sh $APP_ID`

- スコープ: `bot`, `applications.commands`
- 権限: `メッセージを送る`, `メッセージ履歴を読む`, `接続`, `発言`
- **成功判定**: 招待URLが生成され、`discord.com/oauth2/authorize` 形式になっている
- **エラー時**: URL 生成失敗 → スコープ・権限選択を snapshot で確認し再操作
- 出力: 招待URL

### Phase 6: サーバー招待（`$SERVER_ID` 指定時のみ）

`scripts/invite-to-server.sh $INVITE_URL $SERVER_ID`

- 招待URLをブラウザで開く → サーバー選択 → Authorize
- **成功判定**: 「Authorized」メッセージまたはリダイレクト完了
- **エラー時**: CAPTCHA 出現 → `AskUserQuestion` でユーザーに解決を依頼

## 手動介入ポイント

以下の状況では自動化が不可能で、`AskUserQuestion` でユーザーに対応を依頼する:

| ポイント | Phase | 検出方法 | 対処 |
|---|---|---|---|
| hCaptcha | 2 | `iframe[src*=hcaptcha]` | `AskUserQuestion` で CAPTCHA 解決を依頼 |
| 2FA | 3 | `input[type=password]` | `AskUserQuestion` でパスワード入力を依頼 |
| ログイン | 1 | URL が `/login` にリダイレクト | `AskUserQuestion` でログインを依頼 |
| サーバー招待 | 6 | 複雑な UI のため | `AskUserQuestion` で Authorize を依頼 |

## 技術的な注意事項（要約）

## よくある問題と対処

| 症状 | 原因 | 対処 |
|------|------|------|
| hCaptcha 出現 | Bot作成の検証 | ユーザーにエスカレーション |
| 2FA パスワード要求 | トークンリセット時のセキュリティ | ユーザーにエスカレーション |
| /login にリダイレクト | セッション切れ | ユーザーにログインを依頼 |
| セレクタ不一致 | Discord のデプロイ更新 | snapshot で確認し、テキストベース検索に切り替え |
| 保存ボタンが無効 | 変更なし | スキップして次の Phase へ |
| ページロード前の操作エラー | ロード未完了 | `wait --load-state complete --timeout 15` を操作前に入れる |

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

### セマンティック判断
- Claude が snapshot/screenshot で状態を見て判断すべき箇所:
  - モーダルダイアログの内容確認（エラーメッセージの有無）
  - 保存成功メッセージの確認
  - DOM 構造が変わった場合のセレクタ再特定

## cmux browser コマンドリファレンス

本スキルで使用する cmux browser の主要コマンド。

### ブラウザ操作

| 操作 | コマンド |
|------|---------|
| ブラウザ起動 | `cmux browser open "URL"` |
| ページ遷移 | `cmux browser $BSURF goto "URL"` |
| 読み込み待ち | `cmux browser $BSURF wait --load-state complete --timeout 15` |
| スクリーンショット | `cmux browser $BSURF screenshot --out /tmp/file.png` |
| スナップショット | `cmux browser $BSURF snapshot --interactive` |
| URL取得 | `cmux browser $BSURF get url` |

### 要素操作

| 操作 | コマンド |
|------|---------|
| クリック | `cmux browser $BSURF click e2` |
| テキスト入力 | `cmux browser $BSURF fill e3 "TEXT"` |
| JS実行 | `cmux browser $BSURF eval "SCRIPT"` |
| キー押下 | `cmux browser $BSURF press Enter` |

### snapshot vs screenshot の使い分け

**原則: 要素を操作・確認する目的では `snapshot` を使う。`screenshot` はトークンを大量消費するため最終手段にとどめる。**

| 目的 | 使うコマンド |
|------|------------|
| ページ上の要素を探して操作する | `snapshot --interactive` |
| テキスト内容・構造を確認する | `snapshot` |
| 視覚的レイアウトの確認が必要 | `screenshot` |

### Discord UI 操作パターン

**テキストベースのボタンクリック**:
```bash
cmux browser $BSURF eval "
  var btn = Array.from(document.querySelectorAll('button')).find(function(b) {
    return b.textContent.trim() === 'ターゲットテキスト';
  });
  if (btn) btn.setAttribute('data-auto-click', '1');
"
cmux browser $BSURF click "[data-auto-click]"
```

**チェックボックスの操作**（Discord カスタム UI 対応）:
```bash
cmux browser $BSURF eval "
  var cb = document.querySelectorAll('input[type=checkbox]')[INDEX];
  if (cb && !cb.checked) cb.setAttribute('data-auto-cb', '1');
"
cmux browser $BSURF click "[data-auto-cb]"
```

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

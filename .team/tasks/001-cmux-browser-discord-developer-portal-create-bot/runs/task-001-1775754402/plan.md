# 実装計画書: cmux ブラウザ自動化による Discord Bot 作成

cmux のブラウザ操作コマンドを使い、Discord Developer Portal での Bot 作成フローを自動化する。基本操作の検証から始め、手動検証を経てスキルとしてスクリプト化する。

---

## Phase 1: cmux browser 基本操作の確認

### 1.1 ブラウザペインの起動

cmux はワークスペース内の surface（ペイン）でブラウザを操作する。まず surface を取得し、ブラウザを開く。

```bash
# ブラウザペインを開く（URLを指定）
cmux browser open "https://example.com"
# → surface ID が出力される（例: browser-abc123）

# 以降、出力された surface ID を SURFACE 変数に格納して使う
SURFACE="<出力されたsurface ID>"
```

**検証**: `cmux browser $SURFACE get url` で現在のURLを取得し、意図したページが開いているか確認。

### 1.2 基本コマンドの検証手順

各コマンドを https://example.com 等の安全なサイトで検証する。

#### goto（ページ遷移）

```bash
cmux browser $SURFACE goto "https://example.com"
```

- **成功確認**: `cmux browser $SURFACE get url` → `https://example.com` が返る
- **失敗パターン**: surface ID が無効 → エラーメッセージ確認

#### snapshot（DOM構造の取得）

```bash
# 通常のスナップショット
cmux browser $SURFACE snapshot

# インタラクティブ要素のみ（クリック可能なボタン等を探すのに有用）
cmux browser $SURFACE snapshot --interactive

# コンパクト表示
cmux browser $SURFACE snapshot --compact
```

- **成功確認**: DOM ツリーがテキストで出力される
- **用途**: CSS セレクタの特定、ページ状態の確認に使用

#### click（要素クリック）

```bash
cmux browser $SURFACE click --selector "a[href]"
```

- **成功確認**: `snapshot` でページ状態が変わっている / `get url` でURLが遷移している
- **失敗パターン**: セレクタが見つからない → エラーメッセージ確認

#### type / fill（テキスト入力）

```bash
# fill は入力欄をクリアしてから入力
cmux browser $SURFACE fill --selector "input[type=text]" --text "Hello"
```

- **成功確認**: `cmux browser $SURFACE get value --selector "input[type=text]"` → `Hello`
- **`type` vs `fill`**: `fill` はフィールドをクリアしてから入力。`type` はキーストローク単位。フォーム入力には `fill` を優先

#### screenshot（スクリーンショット）

```bash
cmux browser $SURFACE screenshot --out /tmp/test-screenshot.png
```

- **成功確認**: `/tmp/test-screenshot.png` が生成され、Claude の Read ツールで画像を確認可能
- **用途**: 操作結果の視覚確認、エラー状態のデバッグ

#### wait（要素/状態の待機）

```bash
# 特定セレクタが出現するまで待機
cmux browser $SURFACE wait --selector "button.submit" --timeout 10

# 特定テキストが出現するまで待機
cmux browser $SURFACE wait --text "Success" --timeout 10

# URL変化を待機
cmux browser $SURFACE wait --url-contains "/applications/" --timeout 10
```

- **成功確認**: コマンドが正常終了（exit code 0）
- **失敗パターン**: タイムアウト → exit code 非ゼロ

#### find（要素検索）

```bash
# ロールで検索（ボタン、リンク等）
cmux browser $SURFACE find role button --name "Create"

# テキストで検索
cmux browser $SURFACE find text "New Application"
```

- **成功確認**: マッチした要素の情報が出力される
- **用途**: CSS セレクタが不明な場合にロールやテキストで要素を特定

### 1.3 コマンド連携パターン

実際の自動化で頻出するパターンを検証する。

```bash
# パターン: クリック → 待機 → スナップショット
cmux browser $SURFACE click --selector "a[href]"
cmux browser $SURFACE wait --load-state complete --timeout 10
cmux browser $SURFACE snapshot --interactive

# パターン: 入力 → スナップショットで確認
cmux browser $SURFACE fill --selector "input" --text "TestValue"
cmux browser $SURFACE snapshot --selector "input"

# パターン: 操作 → スクリーンショットで視覚確認
cmux browser $SURFACE click --selector "button[type=submit]"
cmux browser $SURFACE screenshot --out /tmp/after-submit.png
```

### 1.4 Phase 1 の完了条件

- [ ] `cmux browser open` でブラウザペインが作成できる
- [ ] `goto`, `click`, `fill`, `snapshot`, `screenshot`, `wait`, `find`, `check`, `uncheck` が動作する
- [ ] 各コマンドのエラー時の挙動（無効なセレクタ、タイムアウト等）が把握できている
- [ ] `--snapshot-after` オプションの動作が確認できている
- [ ] 条件なし `wait --timeout N` の動作確認（条件付き `wait --load-state`/`wait --selector` との比較。条件なしが単純スリープとして機能するか、それとも別の挙動をするか検証する）
- [ ] `find` コマンドの `--name` パラメータの動作確認（`find role button --name "Create"` 等）
- [ ] `check` / `uncheck` コマンドの冪等性の確認（既に ON の状態で `check` → 変化なし、既に OFF の状態で `uncheck` → 変化なし）

### 1.5 実験記録フォーマット（Phase 1-2 共通）

Phase 1・Phase 2 の各コマンド検証結果を `runs/` ディレクトリに記録する。

**記録先**: `runs/task-001-1775754402/experiments/`

**ファイル命名**: `phase{N}-{step}-{description}.md`（例: `phase1-1.2-click.md`, `phase2-2.1-create-app.md`）

**フォーマット**:

```markdown
# 実験: {タイトル}

- **Phase**: {Phase番号}
- **日時**: {YYYY-MM-DD HH:MM}
- **対象URL**: {操作対象のURL}

## 実行コマンド

\```bash
{実際に実行したコマンド（コピー＆ペースト可能な形式）}
\```

## 結果

- **exit code**: {0 or 非ゼロ}
- **出力（抜粋）**: {重要部分のみ。トークン等の秘密情報は含めない}
- **成功/失敗**: {成功 / 失敗}

## 発見事項

- {コマンドの挙動で想定と異なった点、セレクタの特定結果、エラーパターン等}

## 次のアクション

- {この結果を踏まえて次に試すべきこと}
```

**注意**: スクリーンショットは `runs/task-001-1775754402/screenshots/` に保存し、実験記録からファイル名で参照する。

---

## Phase 2: Discord Developer Portal での手動検証

### 2.0 ログイン済みセッションの確認

Discord Developer Portal はログインが必要。cmux は既存のブラウザセッションを使うため、事前にブラウザでログインしておく必要がある。

```bash
# ポータルを開く
cmux browser open "https://discord.com/developers/applications"
# → SURFACE ID を取得

# ログイン状態を確認
cmux browser $SURFACE wait --url-contains "/developers/applications" --timeout 10

# ログインページにリダイレクトされた場合
cmux browser $SURFACE get url
# → "https://discord.com/login" ならログインが必要
```

**ログインしていない場合の対処**:
1. `cmux browser $SURFACE screenshot` でスクリーンショットを撮り、ユーザーに通知
2. ユーザーに手動でログインしてもらう
3. ログイン後、`cmux browser $SURFACE wait --url-contains "/developers/applications"` で確認

### 2.1 Phase 1: アプリケーション作成

#### ステップ 1: Developer Portal を開く

```bash
cmux browser $SURFACE goto "https://discord.com/developers/applications"
cmux browser $SURFACE wait --url-contains "/developers/applications" --timeout 15
cmux browser $SURFACE snapshot --interactive
```

**検証**: snapshot でアプリケーション一覧ページが表示されていること。"New Application" ボタンが存在すること。

#### ステップ 2: "New Application" ボタンをクリック

```bash
# セレクタ候補（実験で特定する）:
# - find で探す
cmux browser $SURFACE find role button --name "New Application"
# - または snapshot --interactive の出力から CSS セレクタを特定

cmux browser $SURFACE click --selector "<新規アプリケーションボタンのセレクタ>" --snapshot-after
cmux browser $SURFACE wait --selector "<モーダルダイアログのセレクタ>" --timeout 10
cmux browser $SURFACE snapshot --interactive
```

**検証**: モーダルダイアログが表示され、アプリケーション名の入力欄が見えること。

#### ステップ 3: アプリケーション名を入力

```bash
# 名前入力欄のセレクタを特定（snapshot --interactive の出力から）
cmux browser $SURFACE fill --selector "<名前入力欄のセレクタ>" --text "$BOT_NAME" --snapshot-after
```

**検証**: snapshot で入力欄に名前が入力されていること。

#### ステップ 4: ToS 同意チェック → Create

```bash
# ToS チェックボックスを有効化（check で冪等に）
cmux browser $SURFACE check --selector "<ToSチェックボックスのセレクタ>" --snapshot-after

# Create ボタンをクリック
cmux browser $SURFACE click --selector "<Createボタンのセレクタ>"

# アプリケーション詳細ページへの遷移を待機
cmux browser $SURFACE wait --url-contains "/applications/" --timeout 15
cmux browser $SURFACE screenshot --out /tmp/discord-app-created.png
```

**検証**: URLが `/developers/applications/{app_id}/information` に遷移していること。スクリーンショットでアプリケーション設定ページが表示されていること。

**エラーケース**:
- 名前が既に使用されている → snapshot でエラーメッセージを確認、ユーザーに別名を提案
- CAPTCHA が表示される → screenshot でユーザーに通知し、手動対応を依頼
- レート制限 → エラーメッセージを確認、待機後にリトライ

#### ステップ 5: Application ID を取得

```bash
# URLから Application ID を抽出（macOS 互換: sed を使用。grep -oP は BSD grep 非対応）
APP_URL=$(cmux browser $SURFACE get url)
APP_ID=$(echo "$APP_URL" | sed -n 's|.*/applications/\([0-9]*\).*|\1|p')
echo "Application ID: $APP_ID"
```

**注意**: `grep -oP`（Perl 正規表現）は macOS の BSD grep では使用不可。`sed` または bash パラメータ展開 `APP_ID="${APP_URL##*/applications/}"; APP_ID="${APP_ID%%/*}"` を使うこと。

### 2.2 Phase 2: Bot 有効化・トークン取得

#### ステップ 1: Bot 設定ページへ遷移

```bash
# Bot ページに直接遷移
cmux browser $SURFACE goto "https://discord.com/developers/applications/$APP_ID/bot"
cmux browser $SURFACE wait --load-state complete --timeout 15
cmux browser $SURFACE snapshot --interactive
```

**検証**: Bot 設定ページが表示されていること。2024年以降、Bot はアプリケーション作成時に自動生成されるため、"Add Bot" ボタンではなく Bot 情報が既に表示されているはず。

#### ステップ 2: Reset Token でトークンを取得

```bash
# "Reset Token" ボタンを探す
cmux browser $SURFACE find role button --name "Reset Token"

# クリック
cmux browser $SURFACE click --selector "<Reset Tokenボタンのセレクタ>"
cmux browser $SURFACE wait --selector "<確認ダイアログのセレクタ>" --timeout 10

# 確認ダイアログが出る場合（"Yes, do it!" 等）
cmux browser $SURFACE click --selector "<確認ボタンのセレクタ>"
cmux browser $SURFACE wait --selector "<トークン表示要素のセレクタ>" --timeout 10
```

**検証**: `get value` または `get text` でトークン文字列が取得できること。

**重要**: トークン表示後に `snapshot` や `screenshot` を**絶対に実行しない**こと。トークンが出力やファイルに漏洩するリスクがある。

#### ステップ 3: トークンを安全に取得・保存

```bash
# トークンをピンポイントで取得（snapshot/screenshot は使わない）
BOT_TOKEN=$(cmux browser $SURFACE get value --selector "<トークン入力欄のセレクタ>")
# get value で取れない場合は get text を試す
# BOT_TOKEN=$(cmux browser $SURFACE get text --selector "<トークン表示要素のセレクタ>")

# トークンの妥当性を簡易チェック（中身は表示しない）
if [ -z "$BOT_TOKEN" ]; then
  echo "ERROR: トークンの取得に失敗しました" >&2
  exit 1
fi
echo "トークンを取得しました（${#BOT_TOKEN} 文字）"

# トークン表示を閉じる（漏洩防止: ページ遷移で表示を消す）
cmux browser $SURFACE goto "https://discord.com/developers/applications/$APP_ID/bot"
cmux browser $SURFACE wait --load-state complete --timeout 15

# ファイルに保存する場合は umask 077 で他ユーザーから読めないようにする
(umask 077; echo "$BOT_TOKEN" > "$TOKEN_OUTPUT_FILE")
```

**セキュリティ注意**:
- トークンはログや画面出力に**絶対に残さない**
- `snapshot --interactive` や `screenshot` はトークン表示中に実行しない
- トークン取得後は速やかにページ遷移してトークン表示を閉じる
- ファイル保存時は `umask 077` でパーミッションを制限（owner のみ読み書き可能）
- 変数に格納して使用し、完了時は文字数のみ通知

#### ステップ 4: Privileged Gateway Intents の設定

```bash
# MESSAGE CONTENT INTENT のトグルを有効化
cmux browser $SURFACE snapshot --interactive
# → トグルの現在の状態を確認

# 各 Intent のトグルを有効化（check は冪等: 既に ON なら何もしない）
cmux browser $SURFACE check --selector "<MESSAGE CONTENT INTENTトグルのセレクタ>" --snapshot-after
cmux browser $SURFACE check --selector "<SERVER MEMBERS INTENTトグルのセレクタ>" --snapshot-after
cmux browser $SURFACE check --selector "<PRESENCE INTENTトグルのセレクタ>" --snapshot-after

# 設定を保存（Save Changes ボタン）
cmux browser $SURFACE click --selector "<Save Changesボタンのセレクタ>" --snapshot-after
cmux browser $SURFACE wait --selector "<保存完了を示す要素のセレクタ>" --timeout 10
cmux browser $SURFACE screenshot --out /tmp/discord-bot-intents.png
```

**検証**: スクリーンショットで3つの Intent トグルが ON になっていること。

**重要**: `click` ではなく `check` を使用する。`click` はトグルの現在状態に関わらず切り替えてしまい、冪等性が破綻する。`check` は既に ON の場合は何もしないため安全。無効化する場合は `uncheck` を使用する。

**エラーケース**:
- 保存ボタンが無効化されている → 変更がないことを確認（全トグルが既にON）

### 2.3 Phase 3: OAuth2 招待URL生成

#### ステップ 1: OAuth2 URL Generator ページへ遷移

```bash
cmux browser $SURFACE goto "https://discord.com/developers/applications/$APP_ID/oauth2"
cmux browser $SURFACE wait --load-state complete --timeout 15
cmux browser $SURFACE snapshot --interactive
```

**注意**: OAuth2 ページ内の "URL Generator" セクションは、ページ下部またはサブタブにある可能性がある。snapshot で構造を確認する。

#### ステップ 2: Scopes の選択

```bash
# "bot" スコープのチェックボックスを探して有効化（check で冪等に）
cmux browser $SURFACE find text "bot"
cmux browser $SURFACE check --selector "<botチェックボックスのセレクタ>" --snapshot-after

# "applications.commands" スコープを選択
cmux browser $SURFACE check --selector "<applications.commandsチェックボックスのセレクタ>" --snapshot-after
```

#### ステップ 3: Bot Permissions の選択

```bash
# 基本的な権限を選択（check で冪等に）
# Send Messages
cmux browser $SURFACE check --selector "<Send Messagesチェックボックスのセレクタ>" --snapshot-after
# Read Message History
cmux browser $SURFACE check --selector "<Read Message Historyチェックボックスのセレクタ>" --snapshot-after
# Connect (ボイス)
cmux browser $SURFACE check --selector "<Connectチェックボックスのセレクタ>" --snapshot-after
# Speak (ボイス)
cmux browser $SURFACE check --selector "<Speakチェックボックスのセレクタ>" --snapshot-after

cmux browser $SURFACE screenshot --out /tmp/discord-oauth2-permissions.png
```

#### ステップ 4: 招待URLを取得

```bash
# Generated URL セクションからURLをコピー
cmux browser $SURFACE snapshot --interactive
# → "Generated URL" ラベルの近くにある input/textarea を探す

INVITE_URL=$(cmux browser $SURFACE get value --selector "<招待URL表示欄のセレクタ>")
# または
INVITE_URL=$(cmux browser $SURFACE eval "document.querySelector('<セレクタ>').value")
```

### 2.4 Phase 4: サーバーへの招待（オプション）

```bash
# 招待URLをブラウザで開く
cmux browser $SURFACE goto "$INVITE_URL"
cmux browser $SURFACE wait --load-state complete --timeout 15
cmux browser $SURFACE snapshot --interactive

# サーバー選択ドロップダウン
cmux browser $SURFACE click --selector "<サーバー選択ドロップダウンのセレクタ>" --snapshot-after
# → 対象サーバーを選択（server-id ベースで特定）

# "Authorize" ボタンをクリック
cmux browser $SURFACE click --selector "<Authorizeボタンのセレクタ>" --snapshot-after
cmux browser $SURFACE wait --text "Authorized" --timeout 15
cmux browser $SURFACE screenshot --out /tmp/discord-bot-authorized.png
```

**エラーケース**:
- CAPTCHA が表示される → ユーザーに手動操作を依頼
- サーバーの権限が不足 → エラーメッセージを表示

### 2.5 想定エラーケースと対処法

| エラーケース | 検出方法 | 対処法 |
|---|---|---|
| **未ログイン** | URLが `/login` にリダイレクト | ユーザーに手動ログインを依頼 |
| **CAPTCHA** | screenshot で hCaptcha/reCAPTCHA を確認 | ユーザーに手動解決を依頼、完了後に `wait` で再開 |
| **レート制限** | "You are being rate limited" テキスト検出 | 指定秒数待機後にリトライ |
| **名前重複** | モーダル内エラーメッセージ | ユーザーに別名を提案 |
| **2FA 要求** | 2FA入力画面の検出 | ユーザーに手動入力を依頼 |
| **セッション期限切れ** | 操作中にログインページへ遷移 | セッション再確認を促す |
| **DOM構造の変更** | セレクタが見つからない | snapshot で現在の構造を再確認、セレクタを更新 |

---

## Phase 3: 検証済み手順のスキル化

### 3.1 scripts/ に作成するスクリプト一覧

Phase 2 の手動検証で確定したセレクタとコマンドシーケンスを、以下のスクリプトに分割する。

| ファイル | 役割 | 引数 |
|---|---|---|
| `scripts/open-portal.sh` | ブラウザ起動 + ログイン確認 | なし |
| `scripts/create-application.sh` | アプリケーション作成（Phase 1） | `$BOT_NAME` |
| `scripts/get-bot-token.sh` | Bot トークン取得（Phase 2: Reset Token） | `$APP_ID` |
| `scripts/configure-intents.sh` | Privileged Intents 設定（Phase 2: Intents） | `$APP_ID`, `$INTENTS_LIST` |
| `scripts/generate-invite-url.sh` | OAuth2 招待URL生成（Phase 3） | `$APP_ID`, `$SCOPES`, `$PERMISSIONS` |
| `scripts/invite-to-server.sh` | サーバー招待（Phase 4, オプション） | `$INVITE_URL`, `$SERVER_ID` |
| `scripts/helpers/check-login.sh` | ログイン状態確認ヘルパー | `$SURFACE` |
| `scripts/helpers/safe-click.sh` | 安全なクリック（要素存在確認付き） | `$SURFACE`, `$SELECTOR` |
| `scripts/create-bot-main.sh` | **メインオーケストレータ**: 全フェーズを順次実行 | `$BOT_NAME`, `[--server $SERVER_ID]` |

#### メインオーケストレータスクリプト（create-bot-main.sh）の概要

`/create-bot` スキル実行時のエントリポイント。各サブスクリプトを順次呼び出し、フェーズ間の値（APP_ID, BOT_TOKEN, INVITE_URL）を受け渡す。

```bash
#!/bin/bash
# create-bot-main.sh — メインオーケストレータ
# Usage: create-bot-main.sh <BOT_NAME> [--server <SERVER_ID>] [--token-file <PATH>]

set -euo pipefail

BOT_NAME="$1"
# ... 引数パース ...

# Phase 1: ブラウザ起動 + ログイン確認
source scripts/open-portal.sh

# Phase 2: アプリケーション作成
APP_ID=$(source scripts/create-application.sh "$BOT_NAME")

# Phase 3: Bot トークン取得
BOT_TOKEN=$(source scripts/get-bot-token.sh "$APP_ID")

# Phase 4: Intent 設定
source scripts/configure-intents.sh "$APP_ID"

# Phase 5: OAuth2 招待URL生成
INVITE_URL=$(source scripts/generate-invite-url.sh "$APP_ID")

# Phase 6: サーバー招待（オプション）
if [ -n "${SERVER_ID:-}" ]; then
  source scripts/invite-to-server.sh "$INVITE_URL" "$SERVER_ID"
fi

# 結果出力
echo "=== Bot 作成完了 ==="
echo "Application ID: $APP_ID"
echo "招待URL: $INVITE_URL"
echo "トークン: ${TOKEN_OUTPUT_FILE:-（変数に格納済み）} に保存"
```

**代替案**: Claude が SKILL.md の手順を逐次実行する場合は、このスクリプトは不要。その場合、SKILL.md の「操作フロー」セクションが Claude の実行ガイドとなる。Phase 3 でどちらの方式を採用するか決定する。

各スクリプトの設計方針:
- surface ID は環境変数 `$CMUX_SURFACE` で受け渡す
- 各スクリプトは冪等に近い設計（既に実行済みでもエラーにならない）
- 終了コードで成功/失敗を返す（0: 成功, 1: リカバリ可能なエラー, 2: 致命的エラー）
- 各ステップ後に snapshot で状態確認、必要に応じて screenshot をログ出力

### 3.2 SKILL.md の更新内容

Phase 2 で確定したセレクタ情報とスクリプト呼び出しを追記する。

```markdown
## 操作フロー（スクリプト版）

### Phase 1: アプリケーション作成
scripts/open-portal.sh → scripts/create-application.sh $BOT_NAME

### Phase 2: Bot 有効化
scripts/get-bot-token.sh $APP_ID → scripts/configure-intents.sh $APP_ID

### Phase 3: OAuth2 招待URL
scripts/generate-invite-url.sh $APP_ID

### Phase 4: サーバー招待（--server 指定時のみ）
scripts/invite-to-server.sh $INVITE_URL $SERVER_ID
```

また、以下を追記:
- **セマンティック判断ポイント**: Claude が snapshot/screenshot を見て判断すべき箇所の明示
- **手動介入ポイント**: CAPTCHA、2FA、ログイン等でユーザー操作が必要な箇所
- **検証済みセレクタ**: Phase 2 で特定した CSS セレクタの一覧（references/ からの参照）
- **Bot 自動生成フローの差分解消**: 現在の SKILL.md に記載されている「Add Bot → 確認ダイアログ」フローと、実際には Bot がアプリケーション作成時に自動生成される動作との差分を解消する。Phase 2 の手動検証結果に基づき、Bot ページの実際の初期状態（"Add Bot" ボタンの有無、自動生成された Bot の表示内容）を正確に反映する

### 3.3 references/ に記録するUI仕様メモ

Phase 2 の手動検証で判明した実際のDOM構造を記録する。

| ファイル | 内容 |
|---|---|
| `references/portal-flow.md`（既存・更新） | URL一覧、UI構造に実際のセレクタ情報を追記 |
| `references/selectors.md`（新規） | 検証済み CSS セレクタの一覧と検証日 |
| `references/error-patterns.md`（新規） | 各エラーケースの画面パターンと対処テンプレート |

#### selectors.md の形式

```markdown
# 検証済みセレクタ一覧

最終検証日: YYYY-MM-DD

## アプリケーション一覧ページ
- New Application ボタン: `<セレクタ>`
- アプリケーション一覧: `<セレクタ>`

## アプリケーション作成モーダル
- 名前入力欄: `<セレクタ>`
- ToS チェックボックス: `<セレクタ>`
- Create ボタン: `<セレクタ>`

## Bot 設定ページ
- Reset Token ボタン: `<セレクタ>`
- トークン表示欄: `<セレクタ>`
- Message Content Intent トグル: `<セレクタ>`
- Server Members Intent トグル: `<セレクタ>`
- Presence Intent トグル: `<セレクタ>`
- Save Changes ボタン: `<セレクタ>`

## OAuth2 URL Generator
- bot スコープ: `<セレクタ>`
- applications.commands スコープ: `<セレクタ>`
- 各パーミッション: `<セレクタ>`
- Generated URL: `<セレクタ>`
```

### 3.4 エラーハンドリングの設計

```
操作実行
  │
  ├─ 成功 → 次のステップへ
  │
  ├─ セレクタ未検出 → snapshot で再探索 → Claude がセレクタ修正 → リトライ
  │
  ├─ ページ遷移エラー → URL確認 → ログインリダイレクト検出 → ユーザー通知
  │
  ├─ CAPTCHA/2FA → screenshot → ユーザーに手動操作依頼 → wait で完了待ち → 再開
  │
  ├─ レート制限 → エラーメッセージからwait秒数抽出 → sleep → リトライ（最大3回）
  │
  └─ 不明なエラー → screenshot + snapshot を保存 → ユーザーに状況報告 → 中断
```

各スクリプトでの実装パターン:

```bash
# safe-click パターン
click_element() {
  local surface="$1"
  local selector="$2"
  local description="$3"

  # 要素の存在確認
  if ! cmux browser "$surface" is visible --selector "$selector" 2>/dev/null; then
    echo "ERROR: $description が見つかりません (selector: $selector)" >&2
    cmux browser "$surface" screenshot --out "/tmp/error-$(date +%s).png"
    return 1
  fi

  # クリック実行
  cmux browser "$surface" click --selector "$selector"
  return $?
}
```

---

## 成果物一覧

### 作成するファイル

| ファイル | Phase | 説明 |
|---|---|---|
| `skills/create-bot/scripts/open-portal.sh` | 3 | ブラウザ起動・ログイン確認 |
| `skills/create-bot/scripts/create-application.sh` | 3 | アプリケーション作成 |
| `skills/create-bot/scripts/get-bot-token.sh` | 3 | トークン取得 |
| `skills/create-bot/scripts/configure-intents.sh` | 3 | Intent 設定 |
| `skills/create-bot/scripts/generate-invite-url.sh` | 3 | 招待URL生成 |
| `skills/create-bot/scripts/invite-to-server.sh` | 3 | サーバー招待 |
| `skills/create-bot/scripts/helpers/check-login.sh` | 3 | ログイン確認ヘルパー |
| `skills/create-bot/scripts/helpers/safe-click.sh` | 3 | 安全クリックヘルパー |
| `skills/create-bot/scripts/create-bot-main.sh` | 3 | メインオーケストレータ |
| `skills/create-bot/references/selectors.md` | 2-3 | 検証済みセレクタ一覧 |
| `skills/create-bot/references/error-patterns.md` | 2-3 | エラーパターンと対処法 |

### 更新するファイル

| ファイル | Phase | 説明 |
|---|---|---|
| `skills/create-bot/SKILL.md` | 3 | スクリプト呼び出し手順を追記 |
| `skills/create-bot/references/portal-flow.md` | 2-3 | 実際のセレクタ情報を追記 |

---

## リスクと対策

| リスク | 影響度 | 対策 |
|---|---|---|
| **Discord UI の変更** | 高 | セレクタを references/ に集約し、変更時は selectors.md のみ更新。セマンティック層で吸収 |
| **CAPTCHA による自動化阻害** | 高 | 完全自動化は断念し、CAPTCHA 検出時はユーザー介入フローに切り替え |
| **cmux browser のバグ・制限** | 中 | Phase 1 で早期に基本動作を確認。問題があれば workaround を検討 |
| **ログインセッションの管理** | 中 | 既存ブラウザセッションを前提とし、ログイン自動化は対象外 |
| **レート制限** | 低 | 各操作間に適切な wait を入れ、レート制限時はバックオフリトライ |
| **トークンの漏洩** | 高 | トークンは `get value`/`get text` でピンポイント取得。取得中は `snapshot`/`screenshot` を禁止。取得後はページ遷移でトークン表示を閉じる。ファイル保存は `umask 077` でパーミッション制限 |

---

## 完了条件

### Phase 1 完了
- cmux browser の全基本コマンド（open, goto, click, fill, snapshot, screenshot, wait, find, get, is, check, uncheck）の動作が確認できている
- 条件なし `wait --timeout` と条件付き `wait` の動作差分が確認されている
- `find --name` パラメータの動作が確認されている
- `check`/`uncheck` の冪等性が確認されている
- 実験記録が `runs/` に記録されている

### Phase 2 完了
- Discord Developer Portal で Bot 作成の全フロー（Phase 1-4）を cmux コマンドで手動実行し、成功している
- 各ステップの CSS セレクタが特定され、references/selectors.md に記録されている
- エラーケースの検出方法と対処法が確認され、references/error-patterns.md に記録されている
- 実験記録が `runs/` に記録されている

### Phase 3 完了
- 全スクリプト（メインオーケストレータ含む）が作成され、単体で動作する
- SKILL.md がスクリプト呼び出し手順を含む形に更新されている
- SKILL.md の「Add Bot → 確認ダイアログ」と実際の Bot 自動生成フローの差分が解消されている
- `/create-bot TestBot` で Bot 作成の全フローがエンドツーエンドで動作する
- エラーハンドリング（未ログイン、セレクタ未検出）が機能する
- トークン取得時にスクリーンショット/スナップショットへの漏洩がないことが確認されている

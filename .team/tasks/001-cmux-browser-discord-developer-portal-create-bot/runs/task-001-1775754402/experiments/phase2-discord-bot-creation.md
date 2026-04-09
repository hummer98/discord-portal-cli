# 実験: Discord Developer Portal Bot 作成フロー全体

- **Phase**: 2
- **日時**: 2026-04-10 02:35-03:00
- **対象URL**: https://discord.com/developers/applications

## 結果サマリ

- **成功**: Bot 作成フロー全体（アプリ作成→トークン取得→Intent設定→OAuth2 URL生成）を完走
- **Application ID**: 1491855925362036948
- **Bot名**: cmux-test-bot-1775756488
- **トークン**: 72文字（安全に取得済み）
- **招待URL**: 取得済み（permissions=3213312, scope=bot+applications.commands）

## 2.0 ログイン確認

```bash
cmux browser $SURFACE goto "https://discord.com/developers/applications"
cmux browser $SURFACE wait --load-state complete --timeout 15
cmux browser $SURFACE get url
# → https://discord.com/developers/applications（ログイン済み）
```
- **成功**: ログイン済みの状態で一覧ページが表示された

## 2.1 アプリケーション作成

### セレクタ情報
- **「新しいアプリケーション」ボタン**: テキストベースで検索（ハッシュ付きクラスは不安定）
  - 検索方法: `eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '新しいアプリケーション')"`
  - cmux find: `find role button --name "新しいアプリケーション"` — OK だが click は eval 経由が確実
- **モーダル名前入力欄**: `input#appname[name="name"]`
  - fill/get value ともに動作確認済み
- **ToS チェックボックス**: `input[type=checkbox]`（モーダル内唯一）
  - **重要**: `check` コマンドは効かない。`click` が必要（Discord カスタムUI）
- **「作成」ボタン**: テキストベースで検索

### 操作手順（実績）
```bash
# 1. ボタンクリック（eval経由）
cmux browser $SURFACE eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '新しいアプリケーション').click()"
# 2. モーダル待機 + 名前入力
sleep 1
cmux browser $SURFACE fill --selector "input#appname" --text "$BOT_NAME"
# 3. ToSチェック（clickで）
cmux browser $SURFACE click --selector "input[type=checkbox]"
# 4. 作成ボタン
cmux browser $SURFACE eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '作成').click()"
# 5. 遷移待機
cmux browser $SURFACE wait --url-contains "/applications/" --timeout 15
```

### CAPTCHA
- アプリケーション作成時に hCaptcha が表示された
- 自動化不可 → ユーザーにエスカレーション（say コマンド）
- CAPTCHA 解決後、自動的にアプリケーション詳細ページに遷移

### Application ID 取得
```bash
APP_URL=$(cmux browser $SURFACE get url)
APP_ID=$(echo "$APP_URL" | sed -n 's|.*/applications/\([0-9]*\).*|\1|p')
```

## 2.2 Bot トークン取得

### セレクタ情報
- **「トークンをリセット」ボタン**: テキストベースで検索
- **確認ダイアログ「実行します！」ボタン**: テキストベースで検索
- **トークン表示**: テキストノード（Copy/コピーボタンの祖先要素内の直接テキストノード）
- **コピーボタン**: テキストベースで検索 (`Copy` or `コピー`)

### 操作手順（実績）
```bash
# Bot ページに遷移
cmux browser $SURFACE goto "https://discord.com/developers/applications/$APP_ID/bot"
cmux browser $SURFACE wait --load-state complete --timeout 15
# Reset Token
cmux browser $SURFACE eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === 'トークンをリセット').click()"
sleep 1
# 確認ダイアログ
cmux browser $SURFACE eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '実行します！').click()"
# → 2FA が要求された場合はユーザーにエスカレーション
```

### 2FA
- トークンリセット時に多要素認証（パスワード入力）が要求された
- 自動化不可 → ユーザーにエスカレーション

### トークン取得方法
```bash
# 方法1: テキストノードから直接取得（72文字）
BOT_TOKEN=$(cmux browser $SURFACE eval "
  var copyBtn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.includes('Copy') || b.textContent.includes('コピー'); });
  var gp = copyBtn.parentElement.parentElement;
  var token = '';
  gp.childNodes.forEach(function(n) { if (n.nodeType === 3 && n.textContent.trim().length > 20) token = n.textContent.trim(); });
  token;
")
# 方法2: コピーボタンをクリック → クリップボード読み取り（ユーザー提案）
```

### セキュリティ注意
- トークン表示中に snapshot/screenshot は絶対に実行しない
- 取得後は速やかにページ遷移でトークン表示を閉じる

## 2.3 Privileged Gateway Intents 設定

### セレクタ情報
- **Intent チェックボックス**: `document.querySelectorAll('input[type=checkbox]')` のインデックス 2,3,4
  - idx 2: Presence Intent
  - idx 3: Server Members Intent
  - idx 4: Message Content Intent
- **「変更を保存」ボタン**: テキストベースで検索
- **成功メッセージ**: 「Botの更新に成功しました！」

### 操作手順（実績）
```bash
# Intents をONにする（eval でクリック）
cmux browser $SURFACE eval "
  var cbs = document.querySelectorAll('input[type=checkbox]');
  [2,3,4].forEach(function(idx) { if (!cbs[idx].checked) cbs[idx].click(); });
"
# 保存
cmux browser $SURFACE eval "Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === '変更を保存').click()"
```

### 重要発見
- `check` コマンドは Discord のカスタムチェックボックスでは効かない
- `eval` で `cb.click()` を実行すると状態が正しく変更される
- `is checked` の結果は DOM の checked プロパティに基づくが、Discord は独自の状態管理をしている場合がある

## 2.4 OAuth2 招待URL生成

### セレクタ情報
- **スコープチェックボックス**: ラベル内の `input[type=checkbox]` に `data-scope` 属性を付けて特定
  - `eval` の `cb.click()` ではReact状態が更新されないケースがある
  - `cmux browser click --selector` を使うとPlaywright経由で正しくReact状態が更新される
- **権限チェックボックス**: 同様に `data-perm` 属性を付けて `cmux browser click` で操作
- **Generated URL input**: `input.inputWithCopyButton__250fd`（クラスはハッシュ付きで不安定）
  - 安定した特定方法: `value.includes('discord.com/oauth2/authorize')` で検索

### 操作手順（実績）
```bash
# スコープ選択: data属性を付与してからcmux clickで操作
cmux browser $SURFACE eval "
  var labels = document.querySelectorAll('label');
  for (var i = 0; i < labels.length; i++) {
    if (labels[i].textContent.trim() === 'bot' && labels[i].querySelector('input[type=checkbox]')) {
      labels[i].querySelector('input[type=checkbox]').setAttribute('data-scope', 'bot');
      break;
    }
  }
"
cmux browser $SURFACE click --selector "input[data-scope=bot]"

# 同様に applications.commands
# 同様に権限チェックボックス

# URL取得
INVITE_URL=$(cmux browser $SURFACE eval "
  var inputs = document.querySelectorAll('input[type=text]');
  for (var i = 0; i < inputs.length; i++) {
    if (inputs[i].value.includes('discord.com/oauth2/authorize')) { inputs[i].value; break; }
  }
")
```

### 重要発見: eval click vs cmux click
- `eval "cb.click()"` → DOMイベントは発火するが **React 状態が更新されない**（スコープ選択で発生）
- `cmux browser click --selector "..."` → Playwright 経由で正しく React 状態が更新される
- **推奨**: フォーム要素の操作は可能な限り `cmux browser click` を使う
- ただし、セレクタが動的で特定が困難な場合は `eval` で `data-*` 属性を付与してから `cmux browser click` で操作するパターンが有効

## 発見事項まとめ

1. **Discord UIは全てカスタムコンポーネント**: `check`/`uncheck` コマンドは効かない。`click` が必要
2. **eval click vs cmux click**: React アプリでは cmux click（Playwright経由）のほうが確実
3. **セレクタの不安定性**: クラス名にハッシュ（`button_a22cb0` 等）が含まれ、デプロイごとに変わる可能性
4. **安定したセレクタ戦略**: テキストベース検索 + eval で data-* 属性付与 + cmux click
5. **CAPTCHA**: アプリケーション作成時に高確率で出現。自動化不可
6. **2FA**: トークンリセット時に要求される。自動化不可
7. **トークン表示**: テキストノードとして表示。snapshot/screenshot 禁止
8. **Bot は自動生成**: "Add Bot" ボタンは不要。アプリ作成時に自動で Bot が追加される
9. **DOM が大きい**: OAuth2 ページでは snapshot --interactive がタイムアウトする。--max-depth 3 でも不十分
10. **日本語UI**: ボタンテキストが日本語（「新しいアプリケーション」「作成」「変更を保存」等）。ロケールに依存

## 次のアクション

- Phase 3: 検証済み手順をスクリプト化
- コピーボタン + クリップボード読み取り方式でのトークン取得を検証
- スクリプトではテキストベース検索 + data属性付与パターンを標準化

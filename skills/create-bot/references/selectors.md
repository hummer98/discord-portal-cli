# 検証済みセレクタ一覧

最終検証日: 2026-04-10
Discord Developer Portal UI バージョン: 不明（ハッシュ付きクラス使用）

## 重要な注意事項

- Discord は React ベースで、クラス名にハッシュ（例: `button_a22cb0`）が含まれる
- これらのハッシュはデプロイごとに変わるため、**クラス名ベースのセレクタは不安定**
- 安定したセレクタ戦略: **テキストベース検索** + **eval で data-* 属性付与** + **cmux click**
- `check`/`uncheck` コマンドは Discord のカスタムUIでは効かない → `click` を使用

## アプリケーション一覧ページ

URL: `https://discord.com/developers/applications`

| 要素 | セレクタ/検索方法 | 備考 |
|---|---|---|
| 新しいアプリケーション ボタン | テキスト検索: `button` → `textContent === '新しいアプリケーション'` | ハッシュ付きクラス: `primary_a22cb0` |

## アプリケーション作成モーダル

| 要素 | セレクタ | 備考 |
|---|---|---|
| 名前入力欄 | `input#appname[name="name"]` | 安定（id/name属性） |
| ToS チェックボックス | `input[type=checkbox]` | モーダル内唯一。`check` 不可、`click` 必須 |
| 作成ボタン | テキスト検索: `button` → `textContent === '作成'` | |
| キャンセルボタン | テキスト検索: `button` → `textContent === 'キャンセル'` | |

## Bot 設定ページ

URL: `https://discord.com/developers/applications/{APP_ID}/bot`

| 要素 | セレクタ/検索方法 | 備考 |
|---|---|---|
| トークンをリセット ボタン | テキスト検索: `button` → `textContent === 'トークンをリセット'` | |
| 確認ダイアログ「実行します！」 | テキスト検索: `button` → `textContent === '実行します！'` | |
| コピーボタン | テキスト検索: `button` → `textContent.includes('Copy')` または `includes('コピー')` | |
| トークン表示 | Copy ボタンの祖先要素 (parentElement.parentElement) 内のテキストノード (nodeType === 3, length > 20) | ⚠️ snapshot/screenshot 禁止 |
| Bot ユーザー名入力 | `input#bot-username-input[name="username"]` | 安定 |
| 変更を保存 ボタン | テキスト検索: `button` → `textContent === '変更を保存'` | |

### Privileged Gateway Intents

| 要素 | セレクタ | 備考 |
|---|---|---|
| Presence Intent | `document.querySelectorAll('input[type=checkbox]')[2]` | インデックスベース（不安定の可能性） |
| Server Members Intent | `document.querySelectorAll('input[type=checkbox]')[3]` | 同上 |
| Message Content Intent | `document.querySelectorAll('input[type=checkbox]')[4]` | 同上 |

**Intent トグルの安定した特定方法**:
```javascript
// テキスト近接検索で Intent を特定
var cbs = document.querySelectorAll('input[type=checkbox]');
for (var i = 0; i < cbs.length; i++) {
  var container = cbs[i].parentElement;
  for (var j = 0; j < 8; j++) {
    if (container.textContent.indexOf('Presence Intent') >= 0) { /* idx = i */ break; }
    container = container.parentElement;
  }
}
```

## OAuth2 URL ジェネレーター

URL: `https://discord.com/developers/applications/{APP_ID}/oauth2`

| 要素 | セレクタ/検索方法 | 備考 |
|---|---|---|
| スコープチェックボックス | `label` → `textContent === 'bot'` 等 → `querySelector('input[type=checkbox]')` | `check` 不可、`cmux click` 必須（React 状態更新のため） |
| 権限チェックボックス | 同上（`label` → `textContent === 'メッセージを送る'` 等） | |
| Generated URL | `input` → `value.includes('discord.com/oauth2/authorize')` | クラス: `inputWithCopyButton__250fd`（不安定） |
| コピーボタン（URL） | URL input の隣のボタン | |

### 主要スコープ名（日本語UI）

| スコープ | ラベルテキスト |
|---|---|
| bot | `bot` |
| applications.commands | `applications.commands` |

### 主要権限名（日本語UI）

| 権限 | ラベルテキスト |
|---|---|
| Send Messages | `メッセージを送る` |
| Read Message History | `メッセージ履歴を読む` |
| Connect | `接続` |
| Speak | `発言` |
| Administrator | `管理者` |
| Manage Channels | `チャンネルの管理` |
| View Channels | `チャンネルを表示` |

## eval click vs cmux click

| 方法 | React 状態更新 | 用途 |
|---|---|---|
| `eval "element.click()"` | △ 一部のコンポーネントで不整合 | ボタン（非フォーム要素） |
| `cmux browser click --selector` | ○ 確実 | フォーム要素（チェックボックス等） |
| `cmux browser check/uncheck` | × Discord カスタムUIで効かない | 使用しない |

**推奨パターン**: eval で data-* 属性を付与 → cmux click で操作

# Discord Developer Portal UI フロー

## URL

- ポータルトップ: `https://discord.com/developers/applications`
- アプリ詳細: `https://discord.com/developers/applications/{app_id}/information`
- Bot設定: `https://discord.com/developers/applications/{app_id}/bot`
- OAuth2: `https://discord.com/developers/applications/{app_id}/oauth2`

## UI構造（2026年4月時点、日本語UI）

### アプリケーション一覧ページ

- ヘッダー右側に「新しいアプリケーション」ボタン（紫色、primary スタイル）
- アプリケーションリストが表示される
- 表示切替: 小/大ボタン

### アプリケーション作成モーダル

- テキスト入力: `input#appname[name="name"]`
- チェックボックス: 開発者向けサービス利用規約・開発者ポリシーへの同意
- ボタン:「作成」「キャンセル」

### Bot設定ページ

- Bot はアプリケーション作成時に自動生成される（「Add Bot」ボタンは存在しない）
- 「トークンをリセット」ボタンでトークン再生成
  - 確認ダイアログ:「実行します！」「キャンセル」
  - 2FA（パスワード入力）が要求される
  - トークンはテキストノードとして表示、コピーボタン付き
- Bot ユーザー名: `input#bot-username-input[name="username"]`
- Privileged Gateway Intents セクション:
  - Presence Intent トグル（`input[type=checkbox]` インデックス 2）
  - Server Members Intent トグル（インデックス 3）
  - Message Content Intent トグル（インデックス 4）
- 「変更を保存」ボタンで設定保存
- 成功メッセージ:「Botの更新に成功しました！」

### OAuth2 URL ジェネレーター

- 「スコープ」セクション: チェックボックスリスト（ラベル付き label 要素）
- 「Botの権限」セクション: bot スコープ選択後に表示
  - 一般権限 / テキストの権限 / ボイスの権限 に分類
- 「連携タイプ」ドロップダウン:「ギルドのインストール」
- 「生成されたURL」: input 要素（`value.includes('discord.com/oauth2/authorize')`）+ コピーボタン

## cmux 操作パターン（検証済み）

### ブラウザを開く

```bash
# cmux でブラウザペインを作成
OPEN_OUTPUT=$(cmux browser open "https://discord.com/developers/applications")
SURFACE=$(echo "$OPEN_OUTPUT" | sed -n 's/.*surface=\([^ ]*\).*/\1/p')
```

### ページロード待機

```bash
cmux browser $SURFACE wait --load-state complete --timeout 15
```

### テキストベースでボタンをクリック

```bash
# eval で data-* 属性を付与 → cmux click で操作
cmux browser $SURFACE eval "
  var btn = Array.from(document.querySelectorAll('button')).find(function(b) {
    return b.textContent.trim() === 'ターゲットテキスト';
  });
  if (btn) btn.setAttribute('data-auto-click', '1');
"
cmux browser $SURFACE click --selector "[data-auto-click]"
```

### チェックボックス操作

```bash
# check/uncheck コマンドは Discord カスタムUI で効かない
# eval で data-* 付与 → cmux click を使用
cmux browser $SURFACE eval "
  var labels = document.querySelectorAll('label');
  for (var i = 0; i < labels.length; i++) {
    if (labels[i].textContent.trim() === 'ラベルテキスト') {
      labels[i].querySelector('input[type=checkbox]').setAttribute('data-cb', '1');
      break;
    }
  }
"
cmux browser $SURFACE click --selector "input[data-cb]"
```

### スクリーンショットで確認

```bash
# wait --load-state complete の後に実行すること
cmux browser $SURFACE screenshot --out /tmp/portal-state.png
```

### ユーザーへのエスカレーション

```bash
say "⚠️ 人間の介入が必要です: <問題の説明>"
```

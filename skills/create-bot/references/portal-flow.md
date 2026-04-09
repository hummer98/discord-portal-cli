# Discord Developer Portal UI フロー

## URL

- ポータルトップ: `https://discord.com/developers/applications`
- アプリ詳細: `https://discord.com/developers/applications/{app_id}/information`
- Bot設定: `https://discord.com/developers/applications/{app_id}/bot`
- OAuth2: `https://discord.com/developers/applications/{app_id}/oauth2`

## UI構造（2026年4月時点）

### アプリケーション一覧ページ

- ヘッダー右上に "New Application" ボタン（紫色）
- アプリケーションリストが表示される

### アプリケーション作成モーダル

- テキスト入力: アプリケーション名
- チェックボックス: Developer ToS & Policy への同意
- ボタン: "Create"

### Bot設定ページ

- Botはアプリケーション作成時に自動生成される（2024年以降）
- "Reset Token" ボタンでトークン再生成
- Privileged Gateway Intents セクション:
  - PRESENCE INTENT トグル
  - SERVER MEMBERS INTENT トグル
  - MESSAGE CONTENT INTENT トグル

### OAuth2 URL Generator

- Scopes チェックボックスグリッド
- Bot Permissions チェックボックスグリッド
- Generated URL テキスト（コピー可能）

## cmux 操作メモ

### ブラウザを開く

```bash
# cmux でブラウザペインを作成
cmux open --url "https://discord.com/developers/applications"
```

### 要素のクリック・テキスト入力

```bash
# TODO: cmux のブラウザ操作API を調査・検証
# cmux click --selector "button.new-application"
# cmux type --selector "input[name=name]" --text "MyBot"
```

### スクリーンショットで確認

```bash
# 操作結果をスクリーンショットで確認
# cmux screenshot --output /tmp/portal-state.png
```

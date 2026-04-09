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

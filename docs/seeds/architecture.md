# discord-portal-cli アーキテクチャ

## 目的

Discord Developer Portal の操作をCLIから自動化する Claude Code プラグイン。
ブラウザ操作は cmux のターミナルベース自動化で行い、Playwright/Puppeteer のような重量級ツールを不要にする。

## なぜ作るのか

- Discord Bot の追加はCLI対応がなく、毎回ブラウザでポチポチ操作が必要
- 複数Bot（例: 9個）を作成する場合の心理的障壁が非常に高い
- cmux のブラウザ操作機能を使えば、セマンティックな手順書 + 定型スクリプトで自動化可能
- Claude Code プラグインとして公開すれば、誰でも `/create-bot MyBot` で Bot を作成できる

## アーキテクチャ

```
ユーザー
  │ "/create-bot MyBotName"
  ▼
Claude Code (プラグイン)
  │ SKILL.md のセマンティック手順を解釈
  ▼
cmux ブラウザ操作
  │ - ページ遷移
  │ - 要素クリック
  │ - テキスト入力
  │ - スクリーンショット確認
  ▼
Discord Developer Portal (ブラウザ)
  │ - アプリケーション作成
  │ - Bot 有効化・トークン取得
  │ - 権限設定
  │ - 招待URL生成
  ▼
出力: Bot Token + Application ID + 招待URL
```

## 設計方針

### セマンティック + 定型スクリプト

- **セマンティック層（SKILL.md）**: 「何をするか」を自然言語で記述。Claude が状況に応じて判断
- **定型スクリプト層（scripts/）**: cmux コマンドシーケンス。検証済みの操作手順をスクリプト化
- **Claude が繋ぐ**: セマンティック手順を読み → 適切なタイミングでスクリプトを実行 → 結果を確認 → 次のステップへ

### なぜ Playwright ではなく cmux か

| 観点 | Playwright | cmux |
|------|-----------|------|
| セットアップ | Node.js + ブラウザバイナリ DL | 既にインストール済み |
| 認証 | Cookie/Session の受け渡しが複雑 | 既存ブラウザセッションをそのまま使う |
| デバッグ | ヘッドレスだと見えない | ペインで操作を目視確認可能 |
| メンテ | DOM変更でセレクタが壊れる | セマンティック操作で吸収可能 |
| 依存 | 重い | 軽い |

### エラーハンドリング

- 各操作ステップ後にスクリーンショットを撮り、Claude が画面状態を確認
- 期待と異なる場合は Claude が判断してリカバリ or ユーザーに確認
- レート制限やCAPTCHAが出た場合はユーザーに手動操作を依頼

## 将来の拡張

- `delete-bot`: Bot の削除
- `update-bot`: Bot 設定の変更（名前、アバター、権限等）
- `list-bots`: 既存 Bot の一覧表示
- `invite-bot`: 招待URLの生成・サーバーへの追加
- Discord 以外の管理画面操作への汎用化（cmux ブラウザ操作パターンのライブラリ化）

## 開発ロードマップ

1. **Phase 1**: cmux ブラウザ操作の基本パターンを確立（open, click, type, screenshot）
2. **Phase 2**: Discord Developer Portal での create-bot フローを手動検証
3. **Phase 3**: 検証済み手順をスクリプト化・スキル統合
4. **Phase 4**: エラーハンドリング・リトライ追加
5. **Phase 5**: OSS 公開・ドキュメント整備

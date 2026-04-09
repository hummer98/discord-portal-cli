# discord-portal-cli

Discord Developer Portal の操作を cmux ブラウザ自動化で行う Claude Code プラグイン。

## 概要

Discord Bot の作成・設定をCLIから実行可能にする。
ブラウザ操作は cmux（ターミナルマルチプレクサ）経由で行い、Playwright等の重量級ツールを使わない。

## コーディング規約

- **ドキュメント・コメント**: 日本語
- **コード（変数名・関数名）**: 英語
- スクリプトは bash / zsh で記述
- cmux コマンドを使ったブラウザ操作手順はセマンティックに記述し、SKILL.md に集約する

## プラグイン構造

```
.claude-plugin/plugin.json   # プラグインマニフェスト
skills/
  create-bot/
    SKILL.md                  # Bot作成スキル（セマンティック手順 + cmux操作）
    references/               # Discord Developer Portal のUI仕様
    scripts/                  # cmux自動化スクリプト
```

## 開発方針

1. まず `create-bot` スキルを手動で確立する（cmux操作を1ステップずつ検証）
2. 検証済み手順をスクリプト化
3. スキルとして統合し、`/create-bot` で呼び出せるようにする
4. エラーハンドリング・リトライを追加

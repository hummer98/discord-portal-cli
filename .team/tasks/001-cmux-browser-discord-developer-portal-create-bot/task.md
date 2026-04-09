---
id: 001
title: cmux browser で Discord Developer Portal の create-bot フローを実験・実装
priority: high
created_at: 2026-04-09T17:06:42.400Z
---

## タスク
## 目的

cmux browser を実際に操作しながら、Discord Developer Portal での Bot 作成フローを確立し、スキルとして実装する。

## 進め方

### Phase 1: cmux browser 基本操作の確認
- surface で cmux browser を起動
- 基本コマンドを試す: open (URL遷移), click, type, screenshot
- 各コマンドの挙動・レスポンスを把握する

### Phase 2: Discord Developer Portal で手動検証
以下のステップを1つずつ cmux browser で実行し、動作を確認:
1. https://discord.com/developers/applications にアクセス
2. 「New Application」ボタンをクリック
3. アプリケーション名を入力・作成
4. Bot セクションに移動
5. Bot を有効化（Add Bot）
6. Bot Token を取得（Reset Token）
7. 必要な権限を設定（Privileged Gateway Intents 等）
8. OAuth2 → URL Generator で招待URLを生成

各ステップ後にスクリーンショットを撮り、期待通りの画面か確認すること。

### Phase 3: 検証済み手順をスキルに反映
- 動いた手順を skills/create-bot/SKILL.md に反映
- 再利用可能な操作は scripts/ にスクリプト化
- references/ に Discord Developer Portal の UI 仕様をメモ

## 注意事項
- Discord にログイン済みのブラウザセッションが必要。ログインしていない場合はユーザーに手動ログインを依頼すること
- レート制限や CAPTCHA が出た場合もユーザーに通知
- 各ステップで失敗した場合は、原因を記録して次のアプローチを試す
- 実験結果（成功した手順・失敗した手順）を .team/output/ に記録する

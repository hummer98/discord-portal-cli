# タスク割り当て

## タスク内容

---
id: 003
title: skill-creator で create-bot スキルを査閲・改善する
priority: high
created_at: 2026-04-09T18:29:41.018Z
---

## タスク
## 目的

skill-creator ツールを使って skills/create-bot/SKILL.md を査閲（レビュー）し、品質を改善する。

## やること

1. skill-creator の使い方を確認（コマンドヘルプ等）
2. skills/create-bot/SKILL.md を skill-creator に通してレビューを受ける
3. レビュー結果に基づいて SKILL.md を改善する
4. 改善結果を記録する

## 注意
- skill-creator が CLI ツールの場合は `skill-creator` や `npx skill-creator` 等で実行を試みる
- Claude Code プラグインの場合は適切な方法で呼び出す
- ツールが見つからない場合は、代替手段を探す or ユーザーに確認する


## 作業ディレクトリ

すべての作業は git worktree `/Users/yamamoto/git/discord-portal-cli/.worktrees/task-003-1775759395` 内で行う。
```bash
cd /Users/yamamoto/git/discord-portal-cli/.worktrees/task-003-1775759395
```
main ブランチに直接変更を加えてはならない。

ブランチ名: `task-003-1775759395/task`

## 作業開始前の確認（ブートストラップ）

worktree は tracked files のみ含む。作業開始前に以下を確認すること:
- `package.json` があれば `npm install` を実行
- `.gitignore` に記載されたランタイムディレクトリ（`node_modules/`, `dist/`, `workspace/` 等）の有無を確認し、必要なら再構築
- `.envrc` や環境変数の設定

## 出力ディレクトリ

```
/Users/yamamoto/git/discord-portal-cli/.team/tasks/003-skill-creator-create-bot/runs/task-003-1775759395
```

結果サマリーは `/Users/yamamoto/git/discord-portal-cli/.team/tasks/003-skill-creator-create-bot/runs/task-003-1775759395/summary.md` に書き出す。

## マージ先ブランチ

このタスクの成果は `main（デフォルト）` にマージすること。
納品方法（ローカルマージ or PR）は conductor-role.md の完了時の処理に従う。

## 完了通知

全ての処理が完了したら、最後に:
```bash
cmux-team send CONDUCTOR_DONE --surface $CMUX_SURFACE --success true
```

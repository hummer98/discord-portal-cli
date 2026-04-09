# タスク割り当て

## タスク内容

---
id: 002
title: using-cmux を参考にリポジトリを公開可能な状態に整備する
priority: high
created_at: 2026-04-09T18:29:40.779Z
---

## タスク
## 目的

~/git/using-cmux を参考に、discord-portal-cli を Claude Code プラグインとして公開可能な状態にする。

## 参考リポジトリ (~/git/using-cmux) の構造

```
.claude-plugin/
  plugin.json         # マニフェスト（hooks含む）
  marketplace.json    # マーケットプレイスメタデータ（keywords, category, tags）
skills/
  using-cmux/
    SKILL.md           # メインスキル定義（498行、フロントマター + 構造化セクション）
commands/
  cmux.md              # /cmux スラッシュコマンド
  cfork.md             # /cfork サブコマンド
bin/                   # ヘルパースクリプト群
install.sh             # インストール/アンインストールスクリプト（3モード対応）
README.md              # 英語ドキュメント
README.ja.md           # 日本語ドキュメント
CLAUDE.md              # 開発者ガイド
LICENSE
.gitignore
```

## やること

### 1. marketplace.json の作成
`.claude-plugin/marketplace.json` を作成:
- name, owner, plugins 配列
- keywords: ["claude-skill", "discord", "bot", "automation", "cmux", "browser"]
- category: "browser" or "automation"
- tags: ["discord", "bot", "browser-automation", "cmux"]

### 2. plugin.json の更新
- repository フィールドを追加
- version を適切に設定
- 必要なら hooks を追加

### 3. SKILL.md の品質向上
~/git/using-cmux/skills/using-cmux/SKILL.md を参考に:
- フロントマターの形式を揃える（name, description のみのシンプルな形式も検討）
- セクション構造を整理（基本操作、エラーハンドリング、よくあるミス等）
- cmux browser 操作のコマンドリファレンスを追加

### 4. README の整備
using-cmux の README を参考に:
- バナー/ロゴは不要だが、構造を合わせる
- Motivation セクション
- What's Included
- Prerequisites
- Installation（3段階: マーケットプレイス推奨 / Agent Skills / 手動）
- Usage
- License
- README.ja.md も作成（日本語版）

### 5. install.sh の作成
- スキルとコマンドを ~/.claude/ にインストール
- --check / --uninstall モード対応
- カラー出力、エラーハンドリング

### 6. commands/ ディレクトリ
- commands/create-bot.md: /create-bot スラッシュコマンドのクイックリファレンス

### 7. docs/seeds/ の整理
- seeds/ は開発用ドキュメントなので、公開時に必要か判断
- 必要なら docs/ に移動整理

## 参考
- ~/git/using-cmux の各ファイルを直接読んで参考にすること
- 言語: ドキュメントは日本語メイン、README は英語 + 日本語版


## 作業ディレクトリ

すべての作業は git worktree `/Users/yamamoto/git/discord-portal-cli/.worktrees/task-002-1775759380` 内で行う。
```bash
cd /Users/yamamoto/git/discord-portal-cli/.worktrees/task-002-1775759380
```
main ブランチに直接変更を加えてはならない。

ブランチ名: `task-002-1775759380/task`

## 作業開始前の確認（ブートストラップ）

worktree は tracked files のみ含む。作業開始前に以下を確認すること:
- `package.json` があれば `npm install` を実行
- `.gitignore` に記載されたランタイムディレクトリ（`node_modules/`, `dist/`, `workspace/` 等）の有無を確認し、必要なら再構築
- `.envrc` や環境変数の設定

## 出力ディレクトリ

```
/Users/yamamoto/git/discord-portal-cli/.team/tasks/002-using-cmux/runs/task-002-1775759380
```

結果サマリーは `/Users/yamamoto/git/discord-portal-cli/.team/tasks/002-using-cmux/runs/task-002-1775759380/summary.md` に書き出す。

## マージ先ブランチ

このタスクの成果は `main（デフォルト）` にマージすること。
納品方法（ローカルマージ or PR）は conductor-role.md の完了時の処理に従う。

## 完了通知

全ての処理が完了したら、最後に:
```bash
cmux-team send CONDUCTOR_DONE --surface $CMUX_SURFACE --success true
```

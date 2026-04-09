# Design Review

## 判定: Approved

## サマリー

計画書はタスク要件7項目すべてをカバーし、using-cmux のパターンに概ね忠実に沿っている。設計判断5件はいずれも妥当で、実装順序の依存関係も正しい。README.ja.md の具体性不足と、手動インストール時のスクリプトパス問題への対処がやや曖昧な点を除けば、実装者が迷わず作業できる具体性がある。

## 詳細レビュー

### 網羅性

**評価: 良好**

タスク要件の7項目すべてが計画に含まれている:

| タスク要件 | 計画セクション | カバー状況 |
|-----------|--------------|-----------|
| marketplace.json 作成 | 3.1 | ✅ 完全な JSON テンプレート付き |
| plugin.json 更新 | 3.2 | ✅ 完全な JSON テンプレート付き |
| SKILL.md 品質向上 | 3.3 | ✅ 4つのサブタスクに分解 |
| README 整備 | 3.4, 3.5 | ✅ 英語版テンプレート付き |
| install.sh 作成 | 3.6 | ✅ 関数構造定義済み |
| commands/ 作成 | 3.7 | ✅ 完全なテンプレート付き |
| docs/seeds/ 整理 | 3.8 | ✅ 判断と理由付き |

追加で `.gitignore` 更新（3.9）も含まれており、using-cmux との整合性確保として適切。

**軽微な指摘**: using-cmux は CLAUDE.md も整備されている（ファイル構成テーブル、SKILL.md 編集ルール、メンテ手順等）。現在の discord-portal-cli の CLAUDE.md は開発方針のみで、公開リポジトリとしてのコントリビューション情報が不足している。ただしタスク要件に含まれていないため、ブロッカーではない。

### 一貫性

**評価: 良好（1点注意あり）**

using-cmux のパターンとの一致度:

| 項目 | using-cmux | 計画 | 一致 |
|------|-----------|------|------|
| marketplace.json 構造 | `{name, owner, plugins[]}` | 同一構造 | ✅ |
| marketplace.json name | `"hummer98-using-cmux"` | `"yamamoto-discord-portal-cli"` | ✅ |
| plugin.json フィールド | name, version, description, author, license, repository, hooks | 同一 | ✅ |
| SessionStart フック | cmux タブリネーム | 同一コマンド | ✅ |
| SKILL.md フロントマター | name + description のみ | name + description + argument-hint | ⚠️ 意図的差異 |
| README 構造 | Motivation → What's Included → Prerequisites → Installation(3段) → Usage | 同一構造 | ✅ |
| install.sh 3モード | install / --check / --uninstall | 同一 | ✅ |
| .gitignore | .team/output, prompts, docs-snapshot | 同一 | ✅ |

**注意点**: using-cmux の `skills/using-cmux/` 配下は SKILL.md のみ（scripts/ や references/ なし）。discord-portal-cli は `scripts/` と `references/` を持つ。計画はこの構造差異について明示的に触れていない。これ自体は問題ないが（プラグインの性質が異なるため）、計画書内で「using-cmux と異なる点」として一覧化しておくと実装者の判断が容易になる。

### 判断の妥当性

**評価: 5件中5件妥当**

| # | 判断 | 評価 | コメント |
|---|------|------|---------|
| 1 | argument-hint 残す | ✅ 妥当 | UX 上の実利がある。using-cmux は汎用スキルでヒント不要だが、create-bot は引数パターンが明確なのでヒントが有効 |
| 2 | scripts 含めない | ✅ 妥当 | プラグインインストール（推奨）ではリポジトリ全体が利用可能。ただし後述の注意あり |
| 3 | category=automation | ✅ 妥当 | `terminal`（using-cmux）や `browser` より本質を捉えている |
| 4 | repository 仮設定 | ✅ 妥当 | 公開時に差し替える前提で明記されている |
| 5 | docs/seeds 残す | ✅ 妥当 | 機密情報なし。設計経緯を残す価値がある |

**判断2への補足**: `scripts 含めない` は正しい方向性だが、手動インストール時のフォローが不十分。SKILL.md 内のスクリプト参照（`scripts/open-portal.sh` 等、計14箇所）は相対パスであり、`~/.claude/skills/create-bot/SKILL.md` にコピーされた時点で壊れる。計画は「注意書きを追加」としているが、注意書きの具体的な内容や、SKILL.md 内パスをどう表記するか（絶対パス? 環境変数? そのまま?）が未定義。

**Recommendation**: 手動インストール時の SKILL.md 内スクリプトパスの扱いについて、以下のいずれかを明記すべき:
- (a) install.sh 実行時にリポジトリパスを SKILL.md 内に埋め込む（sed 置換）
- (b) SKILL.md 冒頭に「このスキルはプラグインインストールを前提としています。手動インストールの場合はリポジトリディレクトリからの実行が必要です」と注記
- (c) SKILL.md 内のパスを `$PLUGIN_ROOT/skills/create-bot/scripts/...` のような変数形式にする

推奨は (b)。シンプルで、プラグインインストールを推奨する方針とも整合する。

### 実装順序

**評価: 良好**

依存関係の分析:

```
Step 1: marketplace.json + plugin.json  ←  依存なし ✅
    ↓
Step 2: commands/create-bot.md          ←  依存なし（Step 1と並行も可能）
    ↓
Step 3: SKILL.md 品質向上               ←  コマンド定義との整合確認（弱い依存）
    ↓
Step 4: README.md + README.ja.md        ←  SKILL.md 確定後（正しい依存）✅
    ↓
Step 5: install.sh + .gitignore         ←  最終成果物確定後（正しい依存）✅
```

**軽微な指摘**: Step 2（commands/create-bot.md）は Step 1 と並行可能。「SKILL.md 改修前に作成し参照関係を確認」とあるが、commands/create-bot.md は SKILL.md に依存せず、逆方向（SKILL.md が commands を参照）もない。Step 1 と Step 2 を並行にすれば効率が上がる。ただし実装上の大きな影響はない。

### リスク

**評価: 概ね良好（2点指摘）**

計画書が認識しているリスク:
- ✅ repository URL の仮設定（差し替え必要を明記）
- ✅ owner.email の仮設定
- ✅ using-cmux 同時インストール時の SessionStart フック重複（CMUX_NO_RENAME_TAB で対応）
- ✅ 手動インストール時のスクリプトパス問題

**見落とされているリスク**:

1. **`allowed-tools` 削除の影響**: 計画は `allowed-tools: [Bash, Read, Write]` を SKILL.md から削除し「plugin.json レベルで管理」としているが、提案された plugin.json にはツール制限の定義がない。Claude Code のスキルシステムで `allowed-tools` が実際に機能している場合、削除によりスキル実行時のツール制限が失われる可能性がある。using-cmux の SKILL.md にも `allowed-tools` がないため、おそらく不要なフィールドだが、削除前に動作確認が望ましい。

2. **marketplace.json と plugin.json のバージョン同期**: using-cmux では plugin.json が v1.5.1、marketplace.json が v1.4.0 と乖離している。計画では両方 v0.1.0 で開始するが、将来のバージョンアップ時に同期を忘れるリスクがある。CLAUDE.md にバージョン管理ルールを追記するか、CI チェックを検討すべき。

### 実現可能性

**評価: 良好（1点改善推奨）**

各セクションの具体性:

| セクション | 具体性 | テンプレート/コード例 |
|-----------|--------|---------------------|
| marketplace.json | ◎ | 完全な JSON |
| plugin.json | ◎ | 完全な JSON |
| SKILL.md フロントマター | ◎ | Before/After 付き |
| SKILL.md cmux リファレンス | ○ | テーブル + コード例 |
| SKILL.md 構造整理 | △ | 方針のみ、具体的な目次なし |
| SKILL.md エラーテーブル | ◎ | 完全なテーブル |
| README.md | ◎ | ほぼ完全な Markdown |
| README.ja.md | △ | 「日本語訳」としか記載なし |
| install.sh | ○ | 関数名と方針。実装コードなし |
| commands/create-bot.md | ◎ | 完全な Markdown |
| .gitignore | ◎ | 完全な内容 |

**改善推奨**: README.ja.md について、少なくともセクション見出しの日本語訳一覧を示すべき。「日本語訳」だけでは、実装者が Motivation → 動機、What's Included → 含まれるもの、Prerequisites → 前提条件 等の訳語選択で迷う可能性がある。using-cmux の README.ja.md を直接参照すれば解決するが、計画書内で明示しておくとスムーズ。

## Recommendations

以下は承認条件ではなく、実装時に考慮すべき改善提案:

- [ ] 手動インストール時のスクリプトパス問題について、SKILL.md 冒頭に「プラグインインストール推奨。手動の場合はリポジトリルートからの実行が前提」の注記を追加する方針を明記する
- [ ] `allowed-tools` 削除について、削除しても動作に影響がないことを実装時に確認する旨を注記する
- [ ] README.ja.md のセクション見出し日本語訳の指針を追加するか、「using-cmux/README.ja.md の訳語に合わせる」と明記する

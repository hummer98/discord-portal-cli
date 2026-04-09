# Inspection Report

## 判定: GO

全ファイルが揃い、品質・セキュリティ面で重大な問題なし。軽微な改善点あり（Observations 参照）。

## チェック結果

| 項目 | 結果 | コメント |
|---|---|---|
| plan.md との整合性（全ファイル存在） | OK | 成果物一覧の全11ファイル（新規9 + 更新2）が存在。実験記録 Phase 1, Phase 2 も存在 |
| bash -n シンタックスチェック | OK | 全9スクリプトが `bash -n` パス |
| shebang (`#!/bin/bash`) | OK | 全スクリプトに付与済み |
| 実行権限 (chmod +x) | OK | 全スクリプトが `-rwxr-xr-x` |
| エラーハンドリング (`set -euo pipefail`) | OK | 全実行スクリプトに `set -euo pipefail` あり。ヘルパー（source用関数定義）は関数内でリターンコード管理 |
| macOS 互換性 (`grep -oP` 不使用) | OK | `grep -oP` の使用なし。`sed -n` で正規表現処理 |
| トークン漏洩防止（snapshot/screenshot 禁止） | OK | `get-bot-token.sh` にトークン表示中の snapshot/screenshot は一切なし。コメントで禁止を明示 |
| `umask 077` によるトークンファイル保護 | OK | `create-bot-main.sh:64` で `(umask 077; echo "$BOT_TOKEN" > "$TOKEN_OUTPUT_FILE")` |
| トークン表示の即時クローズ | OK | `get-bot-token.sh:93` でトークン取得後にページ遷移してトークン表示を閉じる |
| トークンのログ出力 | OK | 文字数のみ表示（`${#BOT_TOKEN} 文字`）。トークン本体は stdout（親プロセスがキャプチャ）のみ |
| 冪等性 | OK（代替手段） | `check`/`uncheck` コマンドは Discord カスタム UI で効かないため不使用。代わりに `configure-intents.sh:48` で `!cbs[idx].checked` を確認してから `click` する方式で冪等性を実現。実験結果に基づく正当な設計判断 |
| cmux コマンドの正確性 | OK | Phase 1 実験で検証済みのコマンド体系と一致。`eval` + `data-*` 属性付与 + `cmux click` パターンが標準化 |
| SKILL.md 更新（Bot 自動生成差分解消） | OK | 「Add Bot → Yes, do it!」フローが削除され、Bot 自動生成に対応。SKILL.md:107-108 で明記 |
| 実験記録 | OK | Phase 1（基本コマンド検証）、Phase 2（Bot 作成フロー全体）の記録あり。セレクタ、エラーパターン、重要発見が詳細に記録 |

## Observations（改善提案）

### Observation 1: `open-portal.sh` の `set -e` とコマンド置換の組み合わせ

- **ファイル**: `skills/create-bot/scripts/open-portal.sh:13-17`
- **現状**:
  ```bash
  OPEN_OUTPUT=$(cmux browser open "https://discord.com/developers/applications" 2>&1)
  if [ $? -ne 0 ]; then
    echo "ERROR: ブラウザペインの作成に失敗しました: $OPEN_OUTPUT" >&2
    exit 1
  fi
  ```
- **問題**: `set -e` が有効なため、`cmux browser open` が非ゼロ終了した場合、コマンド置換の時点でスクリプトが即座に終了する。`if [ $? -ne 0 ]` のユーザーフレンドリーなエラーメッセージは到達不能
- **影響**: 軽微（スクリプトは失敗時に終了するが、エラーメッセージが出ない）
- **修正案**: `if ! OPEN_OUTPUT=$(cmux browser open ... 2>&1); then` に変更

### Observation 2: `safe-click.sh` のテキスト補間

- **ファイル**: `skills/create-bot/scripts/helpers/safe-click.sh:31-33`
- **現状**: `click_button_by_text` と `click_checkbox_by_label` で `$text` / `$label_text` を JavaScript 文字列内に直接 bash 補間
- **問題**: テキストにシングルクォート等が含まれると JavaScript が壊れる
- **影響**: 現在の使用パターン（日本語の固定テキスト）では問題ないが、汎用利用時に脆弱
- **修正案**: テキストを base64 エンコードして渡すか、`cmux browser find text` + `cmux browser click` パターンに置き換え

### Observation 3: Intent チェックボックスのインデックス依存

- **ファイル**: `skills/create-bot/scripts/configure-intents.sh:22-23`, `references/selectors.md:46-49`
- **現状**: Intent のチェックボックスを `querySelectorAll('input[type=checkbox]')` のインデックス 2,3,4 で特定
- **問題**: Discord が Bot ページに新しいチェックボックスを追加するとインデックスがずれる
- **影響**: Discord UI 更新時にメンテナンスが必要
- **対策案**: `selectors.md:53-62` にテキスト近接検索による安定した特定方法が記載済み。将来的にこの方式への移行を推奨

### Observation 4: `check-login.sh` に `set -euo pipefail` がない

- **ファイル**: `skills/create-bot/scripts/helpers/check-login.sh`
- **現状**: 関数定義ファイルであり、source で読み込まれるため親スクリプトの設定を継承
- **影響**: なし（関数内で `return` で制御しており、正しい設計）
- **備考**: 意図的な設計であれば問題ない。コメントで明示するとより明確

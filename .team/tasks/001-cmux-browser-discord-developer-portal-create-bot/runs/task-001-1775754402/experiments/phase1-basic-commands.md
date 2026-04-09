# 実験: cmux browser 基本コマンド検証

- **Phase**: 1
- **日時**: 2026-04-10 02:30
- **対象URL**: https://example.com, file:///tmp/checkbox-test.html

## 環境

- cmux: 0.63.2 (79) [179b16ce6]
- macOS

## 実行結果サマリ

### browser open
```bash
cmux browser open "https://example.com"
# → OK surface=surface:153 pane=pane:93 placement=split
```
- **成功**: surface ID が返る

### goto
```bash
cmux browser $SURFACE goto "https://www.google.com"
cmux browser $SURFACE get url
# → https://www.google.com/
```
- **成功**: ページ遷移OK

### snapshot
```bash
cmux browser $SURFACE snapshot
cmux browser $SURFACE snapshot --interactive
cmux browser $SURFACE snapshot --compact
```
- **成功**: DOM構造がテキストで出力される
- **注意**: ページロード完了前に実行すると `js_error: Timed out waiting for JavaScript result` エラー
- **対策**: `wait --load-state complete` を先に実行する

### click
```bash
cmux browser $SURFACE click --selector "a[href]"
```
- **成功**: 要素クリック → ページ遷移が発生
- **エラー時**: `Error: not_found: Element "..." not found or not visible` (exit code 1)

### --snapshot-after
```bash
cmux browser $SURFACE click --selector "a[href]" --snapshot-after
```
- **成功**: クリック実行後にスナップショットが自動出力される
- **注意**: ページ遷移を伴うクリックでは、遷移完了前のDOMが返ることがある。遷移後の状態を確認するには `wait` + 明示的 `snapshot` が必要

### fill + get value
```bash
cmux browser $SURFACE fill --selector "textarea[name=q]" --text "Hello cmux"
cmux browser $SURFACE get value --selector "textarea[name=q]"
# → Hello cmux
```
- **成功**: テキスト入力 + 値取得OK

### screenshot
```bash
cmux browser $SURFACE screenshot --out /tmp/test.png
```
- **成功**: PNG ファイルが生成される
- **注意**: ページロード完了前だと `internal_error: Failed to capture snapshot` エラー
- **対策**: `wait --load-state complete` を先に実行する

### wait（条件付き）
```bash
# セレクタ待機
cmux browser $SURFACE wait --selector "a" --timeout 5           # → OK (存在する要素)
cmux browser $SURFACE wait --selector "#nonexistent" --timeout 3 # → Error: timeout (exit 1)

# ロード状態待機
cmux browser $SURFACE wait --load-state complete --timeout 5    # → OK

# URL待機
cmux browser $SURFACE wait --url-contains "example" --timeout 5 # → OK

# テキスト待機
cmux browser $SURFACE wait --text "Example Domain" --timeout 5  # → OK
```
- **全条件付きパターン**: 動作OK

### wait（条件なし）
```bash
time cmux browser $SURFACE wait --timeout 3
# → 0.246 total（即座に返る）
```
- **重要発見**: 条件なし `wait --timeout N` は単純スリープとして機能しない。条件が未指定の場合、即座に成功で返る
- **スリープが必要な場合**: `sleep N` コマンドを使うか、条件付き wait を使う

### find
```bash
cmux browser $SURFACE find role link                     # → OK
cmux browser $SURFACE find role link --name "Learn more" # → OK
cmux browser $SURFACE find text "Learn more"             # → OK
cmux browser $SURFACE find text "NonExistent123"         # → Error: not_found (exit 1)
```
- **成功**: ロール検索、テキスト検索ともに動作
- `--name` パラメータは accessible name でマッチ
- 要素未検出時は `not_found` エラー (exit 1)

### get
```bash
cmux browser $SURFACE get url    # → https://example.com/
cmux browser $SURFACE get title  # → Example Domain
cmux browser $SURFACE get text --selector "h1"  # → Example Domain
```
- **成功**: URL、タイトル、テキスト取得すべてOK

### is
```bash
cmux browser $SURFACE is visible --selector "a"           # → 1
cmux browser $SURFACE is visible --selector "#nonexistent" # → Error: not_found (exit 1)
cmux browser $SURFACE is checked --selector "#cb1"         # → 0 (未チェック)
cmux browser $SURFACE is checked --selector "#cb2"         # → 1 (チェック済み)
```
- **成功**: visible は 1/エラー、checked は 0/1

### check / uncheck（冪等性）
```bash
# cb1: 未チェック → check → 1 (ON)
# cb1: チェック済み → check → 1 (ON, 変化なし = 冪等)
# cb2: チェック済み → uncheck → 0 (OFF)
# cb2: 未チェック → uncheck → 0 (OFF, 変化なし = 冪等)
```
- **成功**: check/uncheck ともに冪等性が確認された

### エラーメッセージ
| 操作 | エラー | exit code |
|---|---|---|
| click 存在しないセレクタ | `not_found: Element "..." not found or not visible` | 1 |
| fill 存在しないセレクタ | `not_found: Element "..." not found or not visible` | 1 |
| wait タイムアウト | `timeout: Condition not met before timeout` | 1 |
| 無効な surface ID | `invalid_params: Missing or invalid surface_id` | 1 |

## 発見事項

1. **snapshot/screenshot はページロード完了後に実行する必要がある** — `wait --load-state complete` を必ず前に入れる
2. **条件なし `wait --timeout N` はスリープではない** — 即座に返る。スリープが必要なら `sleep N` を使う
3. **--snapshot-after はページ遷移を待たない** — 遷移を伴う操作では wait + 明示的 snapshot が必要
4. **check/uncheck は完全に冪等** — 既にONの状態でcheckしてもエラーにならず変化なし
5. **エラーメッセージが明確** — exit code 1 + 説明的なメッセージで失敗検出が容易

## Phase 1 完了チェックリスト

- [x] `cmux browser open` でブラウザペインが作成できる
- [x] `goto`, `click`, `fill`, `snapshot`, `screenshot`, `wait`, `find`, `get`, `is`, `check`, `uncheck` が動作する
- [x] 各コマンドのエラー時の挙動が把握できている
- [x] `--snapshot-after` オプションの動作が確認できている
- [x] 条件なし `wait --timeout N` の動作確認（即座に返る、スリープではない）
- [x] `find` コマンドの `--name` パラメータの動作確認
- [x] `check` / `uncheck` コマンドの冪等性の確認

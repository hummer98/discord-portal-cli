# エラーパターンと対処法

最終検証日: 2026-04-10

## 人間の介入が必要なケース

### hCaptcha
- **発生タイミング**: アプリケーション作成時（「作成」ボタンクリック後）
- **検出方法**: 
  ```javascript
  document.querySelector('[class*=captcha], iframe[src*=hcaptcha], iframe[src*=recaptcha]')
  ```
  またはスクリーンショットで「ちょっと待って！あなた、本当に人間ですよね？」テキストを確認
- **対処**: `say` でユーザーにエスカレーション → CAPTCHA 解決を待機 → URL 変化で完了検出

### 多要素認証（2FA）
- **発生タイミング**: トークンリセット時（「実行します！」クリック後）
- **検出方法**: 
  ```javascript
  document.querySelector('input[type=password]')
  ```
  またはスクリーンショットで「多要素認証」ダイアログを確認
- **対処**: `say` でユーザーにエスカレーション → パスワード入力を待機 → コピーボタン出現で完了検出

### 未ログイン
- **発生タイミング**: Developer Portal アクセス時
- **検出方法**: `cmux browser get url` → `/login` へのリダイレクト
- **対処**: `say` でユーザーにエスカレーション → `/developers/applications` URL への遷移を待機

## 自動リカバリ可能なケース

### セレクタ未検出
- **原因**: Discord UI の更新でDOM構造が変更
- **検出方法**: cmux click/find がエラー (`not_found: Element "..." not found`)
- **対処**: 
  1. `snapshot --interactive` でページ構造を再確認
  2. セレクタを手動で修正
  3. `references/selectors.md` を更新

### ページロード前の操作
- **原因**: `snapshot`/`screenshot` をページロード完了前に実行
- **検出方法**: `js_error: Timed out waiting for JavaScript result` または `internal_error: Failed to capture snapshot`
- **対処**: `wait --load-state complete --timeout 15` を操作前に入れる

### 保存ボタンが無効
- **原因**: 変更がない（全トグルが既にON等）
- **検出方法**: `button.disabled === true`
- **対処**: 変更が不要と判断し、スキップ

## 想定されるが未検証のケース

### レート制限
- **検出方法**: `"You are being rate limited"` テキスト検出
- **対処**: エラーメッセージから待機秒数を抽出 → `sleep` → リトライ（最大3回）

### セッション期限切れ
- **検出方法**: 操作中にログインページへリダイレクト
- **対処**: ログイン状態の再確認 → ユーザーに再ログインを依頼

### 名前重複
- **検出方法**: モーダル内のエラーメッセージ
- **対処**: ユーザーに別名を提案

## エスカレーション用テンプレート

```bash
# CAPTCHA
say "⚠️ 人間の介入が必要です: CAPTCHA が表示されました。ブラウザペインで CAPTCHA を解決してください。"

# 2FA
say "⚠️ 人間の介入が必要です: 多要素認証が要求されました。ブラウザペインでパスワードを入力してください。"

# ログイン
say "⚠️ 人間の介入が必要です: Discord Developer Portal にログインしてください。ブラウザペインでログイン操作を行ってください。"

# 不明なエラー
say "⚠️ 人間の介入が必要です: 予期しないエラーが発生しました。ブラウザペインの状態を確認してください。"
```

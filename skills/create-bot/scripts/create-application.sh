#!/bin/bash
# create-application.sh — Discord アプリケーション作成
# 引数: $1 = BOT_NAME
# 前提: CMUX_SURFACE が設定済み
# 出力（stdout）: Application ID
# 戻り値: 0=成功, 1=失敗
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/safe-click.sh"

BOT_NAME="${1:?引数にBot名を指定してください}"
SURFACE="${CMUX_SURFACE:?CMUX_SURFACE が設定されていません}"

echo "=== アプリケーション「$BOT_NAME」を作成します ===" >&2

# Developer Portal アプリケーション一覧に移動
cmux browser "$SURFACE" goto "https://discord.com/developers/applications"
cmux browser "$SURFACE" wait --load-state complete --timeout 15
sleep 2

# 「新しいアプリケーション」ボタンをクリック
click_button_by_text "$SURFACE" "新しいアプリケーション" "新しいアプリケーションボタン" >&2

# モーダルが表示されるまで待機
sleep 2

# アプリケーション名を入力
cmux browser "$SURFACE" fill --selector "input#appname" --text "$BOT_NAME"

# ToS チェックボックスをクリック（check コマンドは Discord カスタムUIで効かない）
cmux browser "$SURFACE" click --selector "input[type=checkbox]"

# 「作成」ボタンをクリック
click_button_by_text "$SURFACE" "作成" "作成ボタン" >&2

# CAPTCHA 検出 + ページ遷移待機
echo "ページ遷移を待機中（CAPTCHAが表示される場合があります）..." >&2
for i in $(seq 1 60); do
  sleep 5
  URL=$(cmux browser "$SURFACE" get url 2>&1)
  if echo "$URL" | grep -q '/applications/[0-9]'; then
    # Application ID を抽出
    APP_ID=$(echo "$URL" | sed -n 's|.*/applications/\([0-9]*\).*|\1|p')
    echo "アプリケーション作成完了: $APP_ID" >&2
    echo "$APP_ID"
    exit 0
  fi
  # CAPTCHA チェック
  HAS_CAPTCHA=$(cmux browser "$SURFACE" eval "!!document.querySelector('[class*=captcha], iframe[src*=hcaptcha], iframe[src*=recaptcha]')" 2>&1 || true)
  if [ "$HAS_CAPTCHA" = "true" ] && [ "$i" -eq 1 ]; then
    say "⚠️ 人間の介入が必要です: アプリケーション作成時に CAPTCHA が表示されました。ブラウザペインで CAPTCHA を解決してください。"
    echo "CAPTCHA が表示されました。ユーザーの操作を待機中..." >&2
  fi
done

echo "ERROR: アプリケーション作成がタイムアウトしました（5分）" >&2
exit 1

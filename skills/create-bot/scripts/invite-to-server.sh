#!/bin/bash
# invite-to-server.sh — サーバーへの招待（オプション）
# 引数: $1 = INVITE_URL, $2 = SERVER_ID（オプション）
# 前提: CMUX_SURFACE が設定済み
# 戻り値: 0=成功, 1=失敗
# 注意: CAPTCHA が表示される場合あり
set -euo pipefail

INVITE_URL="${1:?引数に招待URL を指定してください}"
SERVER_ID="${2:-}"
SURFACE="${CMUX_SURFACE:?CMUX_SURFACE が設定されていません}"

echo "=== サーバーに Bot を招待します ===" >&2

# 招待URLを開く
cmux browser "$SURFACE" goto "$INVITE_URL"
cmux browser "$SURFACE" wait --load-state complete --timeout 15
sleep 2

# サーバー選択ドロップダウンが表示されるのを待機
cmux browser "$SURFACE" screenshot --out /tmp/discord-invite-page.png 2>/dev/null

echo "招待ページを開きました" >&2
echo "サーバー選択 → Authorize の操作が必要です" >&2

# サーバーの選択と Authorize は UI が複雑なため、ユーザーにエスカレーション
say "⚠️ サーバーへの招待ページを開きました。ブラウザペインでサーバーを選択し、Authorize をクリックしてください。"

# Authorize 完了を待機
for i in $(seq 1 60); do
  sleep 5
  # "Authorized" テキストの検出
  AUTH_DONE=$(cmux browser "$SURFACE" eval "
    document.body.textContent.includes('Authorized') || document.body.textContent.includes('認証しました');
  " 2>&1 || true)

  if [ "$AUTH_DONE" = "true" ]; then
    echo "Bot のサーバー招待が完了しました" >&2
    exit 0
  fi
done

echo "WARNING: 招待完了の確認がタイムアウトしました" >&2
exit 1

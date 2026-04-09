#!/bin/bash
# open-portal.sh — ブラウザ起動 + ログイン確認
# 出力: CMUX_SURFACE 環境変数を設定
# 戻り値: 0=成功, 1=失敗
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/check-login.sh"

echo "=== Discord Developer Portal を開きます ==="

# ブラウザペインを開く
OPEN_OUTPUT=$(cmux browser open "https://discord.com/developers/applications" 2>&1)
if [ $? -ne 0 ]; then
  echo "ERROR: ブラウザペインの作成に失敗しました: $OPEN_OUTPUT" >&2
  exit 1
fi

# surface ID を抽出
CMUX_SURFACE=$(echo "$OPEN_OUTPUT" | sed -n 's/.*surface=\([^ ]*\).*/\1/p')
if [ -z "$CMUX_SURFACE" ]; then
  echo "ERROR: surface ID の取得に失敗しました" >&2
  exit 1
fi
export CMUX_SURFACE
echo "Surface: $CMUX_SURFACE"

# ページロード完了を待機
cmux browser "$CMUX_SURFACE" wait --load-state complete --timeout 15
sleep 2

# ログイン状態を確認
check_login "$CMUX_SURFACE"

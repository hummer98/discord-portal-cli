#!/bin/bash
# generate-invite-url.sh — OAuth2 招待URL生成
# 引数: $1 = APP_ID
#        $2 = SCOPES（カンマ区切り、省略時は "bot,applications.commands"）
#        $3 = PERMISSIONS（カンマ区切り、省略時は基本4権限）
# 前提: CMUX_SURFACE が設定済み
# 出力（stdout）: 招待URL
# 戻り値: 0=成功, 1=失敗
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/safe-click.sh"

APP_ID="${1:?引数に Application ID を指定してください}"
SCOPES="${2:-bot,applications.commands}"
PERMISSIONS="${3:-メッセージを送る,メッセージ履歴を読む,接続,発言}"
SURFACE="${CMUX_SURFACE:?CMUX_SURFACE が設定されていません}"

echo "=== OAuth2 招待URL を生成します ===" >&2

# OAuth2 ページに遷移
cmux browser "$SURFACE" goto "https://discord.com/developers/applications/$APP_ID/oauth2"
cmux browser "$SURFACE" wait --load-state complete --timeout 15
sleep 2

# スコープ選択
IFS=',' read -ra SCOPE_ARRAY <<< "$SCOPES"
for scope in "${SCOPE_ARRAY[@]}"; do
  scope=$(echo "$scope" | xargs) # trim
  echo "スコープ選択: $scope" >&2
  click_checkbox_by_label "$SURFACE" "$scope" "スコープ $scope" >&2
  sleep 1
done

# 権限選択（bot スコープ選択後に Bot Permissions セクションが表示される）
sleep 2
IFS=',' read -ra PERM_ARRAY <<< "$PERMISSIONS"
for perm in "${PERM_ARRAY[@]}"; do
  perm=$(echo "$perm" | xargs) # trim
  echo "権限選択: $perm" >&2
  click_checkbox_by_label "$SURFACE" "$perm" "権限 $perm" >&2
  sleep 1
done

sleep 2

# Generated URL を取得
INVITE_URL=$(cmux browser "$SURFACE" eval "
  var inputs = document.querySelectorAll('input[type=text]');
  var url = '';
  for (var i = 0; i < inputs.length; i++) {
    if (inputs[i].value && inputs[i].value.includes('discord.com/oauth2/authorize')) {
      url = inputs[i].value;
      break;
    }
  }
  url;
" 2>&1)

if [ -z "$INVITE_URL" ]; then
  echo "ERROR: 招待URL の取得に失敗しました" >&2
  cmux browser "$SURFACE" screenshot --out "/tmp/error-invite-url-$(date +%s).png" 2>/dev/null
  exit 1
fi

echo "招待URL を取得しました" >&2
echo "$INVITE_URL"

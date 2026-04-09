#!/bin/bash
# create-bot-main.sh — メインオーケストレータ: Bot 作成フロー全体を実行
# Usage: create-bot-main.sh <BOT_NAME> [--server <SERVER_ID>] [--token-file <PATH>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === 引数パース ===
BOT_NAME=""
SERVER_ID=""
TOKEN_OUTPUT_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --server)
      SERVER_ID="$2"
      shift 2
      ;;
    --token-file)
      TOKEN_OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      if [ -z "$BOT_NAME" ]; then
        BOT_NAME="$1"
      else
        echo "ERROR: 不明な引数: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$BOT_NAME" ]; then
  echo "Usage: $0 <BOT_NAME> [--server <SERVER_ID>] [--token-file <PATH>]" >&2
  exit 1
fi

echo "========================================"
echo "  Discord Bot 作成: $BOT_NAME"
echo "========================================"

# === Phase 1: ブラウザ起動 + ログイン確認 ===
echo ""
echo "--- Phase 1: ブラウザ起動 + ログイン確認 ---"
source "$SCRIPT_DIR/open-portal.sh"
# CMUX_SURFACE が設定される

# === Phase 2: アプリケーション作成 ===
echo ""
echo "--- Phase 2: アプリケーション作成 ---"
APP_ID=$("$SCRIPT_DIR/create-application.sh" "$BOT_NAME")
echo "Application ID: $APP_ID"

# === Phase 3: Bot トークン取得 ===
echo ""
echo "--- Phase 3: Bot トークン取得 ---"
BOT_TOKEN=$("$SCRIPT_DIR/get-bot-token.sh" "$APP_ID")
echo "トークンを取得しました（${#BOT_TOKEN} 文字）"

# トークンをファイルに保存（指定された場合）
if [ -n "$TOKEN_OUTPUT_FILE" ]; then
  (umask 077; echo "$BOT_TOKEN" > "$TOKEN_OUTPUT_FILE")
  echo "トークンを保存: $TOKEN_OUTPUT_FILE"
fi

# === Phase 4: Intent 設定 ===
echo ""
echo "--- Phase 4: Privileged Gateway Intents 設定 ---"
"$SCRIPT_DIR/configure-intents.sh" "$APP_ID"

# === Phase 5: OAuth2 招待URL生成 ===
echo ""
echo "--- Phase 5: OAuth2 招待URL生成 ---"
INVITE_URL=$("$SCRIPT_DIR/generate-invite-url.sh" "$APP_ID")
echo "招待URL: $INVITE_URL"

# === Phase 6: サーバー招待（オプション） ===
if [ -n "$SERVER_ID" ]; then
  echo ""
  echo "--- Phase 6: サーバー招待 ---"
  "$SCRIPT_DIR/invite-to-server.sh" "$INVITE_URL" "$SERVER_ID"
fi

# === 結果出力 ===
echo ""
echo "========================================"
echo "  Bot 作成完了"
echo "========================================"
echo "Application ID: $APP_ID"
echo "招待URL: $INVITE_URL"
if [ -n "$TOKEN_OUTPUT_FILE" ]; then
  echo "トークン: $TOKEN_OUTPUT_FILE に保存済み"
else
  echo "トークン: 変数に格納済み（${#BOT_TOKEN} 文字）"
fi
echo "========================================"

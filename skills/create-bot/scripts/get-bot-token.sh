#!/bin/bash
# get-bot-token.sh — Bot トークン取得（Reset Token → コピーボタン → クリップボード）
# 引数: $1 = APP_ID
# 前提: CMUX_SURFACE が設定済み
# 出力（stdout）: Bot Token
# セキュリティ: snapshot/screenshot はトークン表示中に絶対に実行しない
# 戻り値: 0=成功, 1=失敗
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/safe-click.sh"

APP_ID="${1:?引数に Application ID を指定してください}"
SURFACE="${CMUX_SURFACE:?CMUX_SURFACE が設定されていません}"

echo "=== Bot トークンを取得します (APP_ID: $APP_ID) ===" >&2

# Bot ページに遷移
cmux browser "$SURFACE" goto "https://discord.com/developers/applications/$APP_ID/bot"
cmux browser "$SURFACE" wait --load-state complete --timeout 15
sleep 2

# 「トークンをリセット」ボタンをクリック
click_button_by_text "$SURFACE" "トークンをリセット" "トークンをリセットボタン" >&2
sleep 1

# 確認ダイアログ「実行します！」をクリック
click_button_by_text "$SURFACE" "実行します！" "確認ボタン" >&2

# 2FA が要求される場合がある — 待機してチェック
echo "認証待機中（2FA が要求される場合があります）..." >&2
for i in $(seq 1 60); do
  sleep 5

  # 2FA ダイアログの検出
  HAS_2FA=$(cmux browser "$SURFACE" eval "!!document.querySelector('input[type=password]')" 2>&1 || true)
  if [ "$HAS_2FA" = "true" ] && [ "$i" -eq 1 ]; then
    say "⚠️ 人間の介入が必要です: トークンリセット時に多要素認証（2FA）が要求されました。ブラウザペインでパスワードを入力してください。"
    echo "2FA が要求されました。ユーザーの操作を待機中..." >&2
  fi

  # コピーボタンの出現をチェック（トークンが表示された証拠）
  HAS_COPY=$(cmux browser "$SURFACE" eval "
    var btn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.includes('Copy') || b.textContent.includes('コピー'); });
    !!btn;
  " 2>&1 || true)

  if [ "$HAS_COPY" = "true" ]; then
    echo "トークンが表示されました" >&2
    break
  fi
done

if [ "$HAS_COPY" != "true" ]; then
  echo "ERROR: トークン表示の待機がタイムアウトしました（5分）" >&2
  exit 1
fi

# ⚠️ ここから先、snapshot/screenshot は絶対に実行しない ⚠️

# コピーボタンをクリックしてクリップボードにトークンを取得
cmux browser "$SURFACE" eval "
  var btn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.includes('Copy') || b.textContent.includes('コピー'); });
  if (btn) btn.click();
" >/dev/null 2>&1
sleep 1

# クリップボードからトークンを取得（macOS: pbpaste）
BOT_TOKEN=$(pbpaste 2>/dev/null)

# トークンの妥当性チェック（中身は表示しない）
if [ -z "$BOT_TOKEN" ] || [ ${#BOT_TOKEN} -lt 50 ]; then
  echo "ERROR: トークンの取得に失敗しました（クリップボード: ${#BOT_TOKEN} 文字）" >&2
  # フォールバック: テキストノードから直接取得
  echo "フォールバック: テキストノードから直接取得を試みます..." >&2
  BOT_TOKEN=$(cmux browser "$SURFACE" eval "
    var copyBtn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.includes('Copy') || b.textContent.includes('コピー'); });
    var gp = copyBtn.parentElement.parentElement;
    var token = '';
    gp.childNodes.forEach(function(n) { if (n.nodeType === 3 && n.textContent.trim().length > 20) token = n.textContent.trim(); });
    token;
  " 2>&1)

  if [ -z "$BOT_TOKEN" ] || [ ${#BOT_TOKEN} -lt 50 ]; then
    echo "ERROR: フォールバックでもトークン取得に失敗しました" >&2
    exit 1
  fi
fi

echo "トークンを取得しました（${#BOT_TOKEN} 文字）" >&2

# トークン表示を閉じる（セキュリティ: ページ遷移でトークン表示を消す）
cmux browser "$SURFACE" goto "https://discord.com/developers/applications/$APP_ID/bot" >/dev/null 2>&1
cmux browser "$SURFACE" wait --load-state complete --timeout 15 >/dev/null 2>&1

# トークンを stdout に出力
echo "$BOT_TOKEN"

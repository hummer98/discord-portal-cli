#!/bin/bash
# configure-intents.sh — Privileged Gateway Intents の設定
# 引数: $1 = APP_ID, $2 = INTENTS_LIST（カンマ区切り、省略時は全3つ）
# 前提: CMUX_SURFACE が設定済み
# 戻り値: 0=成功, 1=失敗
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="${1:?引数に Application ID を指定してください}"
INTENTS_LIST="${2:-presence,server_members,message_content}"
SURFACE="${CMUX_SURFACE:?CMUX_SURFACE が設定されていません}"

echo "=== Privileged Gateway Intents を設定します ===" >&2

# Bot ページに遷移
cmux browser "$SURFACE" goto "https://discord.com/developers/applications/$APP_ID/bot"
cmux browser "$SURFACE" wait --load-state complete --timeout 15
sleep 2

# Intent チェックボックスの位置を特定し、必要なものを有効化
# Intent は document.querySelectorAll('input[type=checkbox]') のインデックス 2,3,4
# idx 2: Presence Intent, idx 3: Server Members Intent, idx 4: Message Content Intent

# 有効化する Intent のインデックスリストを構築
INTENT_INDICES=""
if echo "$INTENTS_LIST" | grep -q "presence"; then
  INTENT_INDICES="$INTENT_INDICES 2"
fi
if echo "$INTENTS_LIST" | grep -q "server_members"; then
  INTENT_INDICES="$INTENT_INDICES 3"
fi
if echo "$INTENTS_LIST" | grep -q "message_content"; then
  INTENT_INDICES="$INTENT_INDICES 4"
fi

if [ -z "$INTENT_INDICES" ]; then
  echo "有効化する Intent がありません" >&2
  exit 0
fi

# eval で各 Intent の状態を確認し、未チェックのものをクリック
CHANGED=$(cmux browser "$SURFACE" eval "
  var cbs = document.querySelectorAll('input[type=checkbox]');
  var indices = [${INTENT_INDICES// /,}];
  var changed = [];
  indices.forEach(function(idx) {
    if (cbs[idx] && !cbs[idx].checked) {
      cbs[idx].click();
      changed.push(idx);
    }
  });
  JSON.stringify(changed);
" 2>&1)

echo "変更した Intent: $CHANGED" >&2

# 変更があった場合のみ保存
if [ "$CHANGED" = "[]" ]; then
  echo "全ての Intent は既に有効です" >&2
  exit 0
fi

sleep 1

# 「変更を保存」ボタンをクリック
cmux browser "$SURFACE" eval "
  var btn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.trim() === '変更を保存'; });
  if (btn && !btn.disabled) { btn.click(); 'clicked'; } else { 'not_found_or_disabled'; }
" >&2

sleep 2

# 保存成功の確認
SUCCESS=$(cmux browser "$SURFACE" eval "
  var el = Array.from(document.querySelectorAll('div, span')).find(function(e) { return e.textContent.includes('成功') || e.textContent.includes('Success'); });
  !!el;
" 2>&1 || true)

if [ "$SUCCESS" = "true" ]; then
  echo "Intent 設定の保存に成功しました" >&2
else
  echo "WARNING: 保存成功メッセージが検出できませんでした（保存自体は成功している可能性あり）" >&2
fi

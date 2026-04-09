#!/bin/bash
# check-login.sh — Discord Developer Portal のログイン状態を確認
# 使用法: source helpers/check-login.sh
# 関数: check_login $SURFACE
# 戻り値: 0=ログイン済み, 1=未ログイン（ユーザー介入が必要）

check_login() {
  local surface="$1"

  local url
  url=$(cmux browser "$surface" get url 2>&1)

  if echo "$url" | grep -q "/login"; then
    echo "⚠️ Discord Developer Portal にログインしていません" >&2
    echo "ブラウザペインで手動でログインしてください" >&2
    say "⚠️ 人間の介入が必要です: Discord Developer Portal にログインしてください。ブラウザペインでログイン操作を行ってください。"
    # ログイン完了を待機
    for i in $(seq 1 60); do
      sleep 5
      url=$(cmux browser "$surface" get url 2>&1)
      if echo "$url" | grep -q "/developers/applications"; then
        echo "ログイン確認完了"
        return 0
      fi
      echo "ログイン待機中... ($((i*5))秒)" >&2
    done
    echo "ERROR: ログイン待機がタイムアウトしました（5分）" >&2
    return 1
  fi

  if echo "$url" | grep -q "/developers/applications"; then
    echo "ログイン済み"
    return 0
  fi

  echo "ERROR: 予期しないURL: $url" >&2
  return 1
}

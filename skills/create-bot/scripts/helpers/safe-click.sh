#!/bin/bash
# safe-click.sh — 安全なクリック（要素存在確認付き）
# 使用法: source helpers/safe-click.sh
# 関数: safe_click $SURFACE $SELECTOR "$DESCRIPTION"

safe_click() {
  local surface="$1"
  local selector="$2"
  local description="${3:-要素}"

  if ! cmux browser "$surface" is visible --selector "$selector" 2>/dev/null; then
    echo "ERROR: $description が見つかりません (selector: $selector)" >&2
    cmux browser "$surface" screenshot --out "/tmp/error-$(date +%s).png" 2>/dev/null
    return 1
  fi

  cmux browser "$surface" click --selector "$selector"
  return $?
}

# テキストベースでボタンを検索してクリック（Discordのハッシュ付きクラス対策）
# eval でボタンを検索し、data属性を付与してから cmux click でクリック
click_button_by_text() {
  local surface="$1"
  local text="$2"
  local description="${3:-ボタン}"
  local attr_name="data-auto-click-$(date +%s)"

  # eval でボタンにユニーク属性を付与
  local result
  result=$(cmux browser "$surface" eval "
    var btn = Array.from(document.querySelectorAll('button')).find(function(b) { return b.textContent.trim() === '$text'; });
    if (btn) { btn.setAttribute('$attr_name', '1'); 'found'; } else { 'not_found'; }
  " 2>&1)

  if [ "$result" = "not_found" ]; then
    echo "ERROR: $description が見つかりません (text: $text)" >&2
    return 1
  fi

  cmux browser "$surface" click --selector "[$attr_name]"
  return $?
}

# チェックボックスをラベルテキストで検索してクリック
# Discord のカスタムUI対策: check コマンドではなく click を使用
click_checkbox_by_label() {
  local surface="$1"
  local label_text="$2"
  local description="${3:-チェックボックス}"
  local attr_name="data-auto-cb-$(date +%s)"

  local result
  result=$(cmux browser "$surface" eval "
    var labels = document.querySelectorAll('label');
    for (var i = 0; i < labels.length; i++) {
      if (labels[i].textContent.trim() === '$label_text' && labels[i].querySelector('input[type=checkbox]')) {
        labels[i].querySelector('input[type=checkbox]').setAttribute('$attr_name', '1');
        'found';
        break;
      }
    }
  " 2>&1)

  if [ "$result" != "found" ]; then
    echo "ERROR: $description が見つかりません (label: $label_text)" >&2
    return 1
  fi

  cmux browser "$surface" click --selector "[$attr_name]"
  return $?
}

# Design Review: plan.md

## 判定: Changes Requested

## Good Points

- **段階的アプローチが適切**: Phase 1（基本操作確認）→ Phase 2（手動検証）→ Phase 3（スクリプト化）という段階設計は、ブラウザ自動化の不確実性を考慮した堅実な進め方
- **エラーケースの網羅**: 未ログイン、CAPTCHA、2FA、レート制限、セッション期限切れ、DOM構造変更など、ブラウザ自動化で想定される主要なエラーケースを表形式で整理している
- **冪等性への意識**: 各スクリプトが「既に実行済みでもエラーにならない」設計方針を明示している
- **セレクタの外部化**: `references/selectors.md` にセレクタを集約し、Discord UI 変更時の影響を局所化する設計は保守性が高い
- **safe-click パターン**: 要素の存在確認→クリック→エラー時スクリーンショットという防御的パターンが具体的に示されている
- **スクリプト分割の粒度**: 機能単位（ポータル起動、アプリ作成、トークン取得、Intent設定、URL生成、招待）に分割されており適切
- **Phase 1 の完了条件**: `--snapshot-after` オプションの確認を含めており、効率化に繋がる発見を促している

## Issues

### Issue 1: `grep -oP` は macOS で動作しない

- **問題**: Phase 2.1 ステップ 5（Application ID 取得）で `grep -oP '/applications/\K[0-9]+'` を使用しているが、macOS（darwin）の BSD grep は `-P`（PCRE）をサポートしていない。本プロジェクトのターゲット環境は darwin
- **推奨**: 以下のいずれかに変更:
  ```bash
  # sed を使用
  APP_ID=$(echo "$APP_URL" | sed -n 's|.*/applications/\([0-9]*\).*|\1|p')
  # または bash パラメータ展開
  APP_ID="${APP_URL##*/applications/}" && APP_ID="${APP_ID%%/*}"
  # または cmux browser eval で直接取得
  APP_ID=$(cmux browser $SURFACE eval "location.pathname.match(/\/applications\/(\d+)/)?.[1]")
  ```

### Issue 2: Intent トグルに `click` ではなく `check` / `uncheck` を使うべき

- **問題**: Phase 2.2 ステップ 4 で Privileged Gateway Intents のトグルを `click` で操作しているが、`click` はトグルの現在状態に関わらず切り替えてしまう。既に ON のトグルを `click` すると OFF になり、冪等性が破綻する
- **推奨**: cmux browser には `check` / `uncheck` コマンドがある（コマンド一覧に明記）。これを使えば、既に ON の場合はスキップされる:
  ```bash
  cmux browser $SURFACE check --selector "<MESSAGE CONTENT INTENTトグルのセレクタ>"
  cmux browser $SURFACE check --selector "<SERVER MEMBERS INTENTトグルのセレクタ>"
  cmux browser $SURFACE check --selector "<PRESENCE INTENTトグルのセレクタ>"
  ```
  冪等性の確保という設計方針と整合し、`is checked` による事前確認も不要になる

### Issue 3: 条件なし `wait --timeout` の多用

- **問題**: 計画書の複数箇所で `cmux browser $SURFACE wait --timeout 3` のように、条件なし（`--selector` も `--text` も `--url-contains` もなし）の `wait` を使用している。cmux の `wait` コマンドは条件付き待機を意図した設計であり、条件なしの場合の動作が不明確。単なるスリープとして機能するか保証がない
- **推奨**: 
  - 条件なしスリープが必要な場合は `sleep 3` を明示的に使用
  - 可能な限り、具体的な条件を指定する:
    ```bash
    # ❌ 条件なし
    cmux browser $SURFACE wait --timeout 3
    
    # ✅ ページロード完了を待機
    cmux browser $SURFACE wait --load-state complete --timeout 5
    
    # ✅ 特定要素の出現を待機
    cmux browser $SURFACE wait --selector "<次に操作する要素>" --timeout 5
    ```
  - Phase 1 の検証項目に「条件なし wait の動作確認」を追加すれば、Phase 2 以降で適切に使い分けられる

### Issue 4: トークン取得時のスクリーンショットによる漏洩リスク

- **問題**: リスク対策表で「スクリーンショットにトークンが写らないよう注意」と記載しているが、Phase 2.2 の手順ではトークンリセット後に `snapshot --interactive` を実行しており、snapshot 出力にトークン文字列が含まれる可能性が高い。snapshot の出力はターミナルに表示されるため、スクロールバック、tmux バッファ、ログファイル等に残る
- **推奨**:
  - トークン取得は `get value` / `get text` で対象要素のみピンポイントに取得し、snapshot は使わない
  - トークンが表示されている状態での `screenshot` も避ける
  - スクリプト化の際は、トークン取得後すぐにページ遷移するか、トークン表示を閉じる操作を入れる
  - 取得したトークンは `echo` せず、ファイルに直接書き出すか環境変数にのみ保持:
    ```bash
    # ❌ ターミナルに出力される
    echo "Token: $BOT_TOKEN"
    
    # ✅ ファイルに直接保存（パーミッション制限付き）
    umask 077 && echo "$BOT_TOKEN" > "$TOKEN_FILE"
    ```

## Recommendations

### R1: `--snapshot-after` の積極活用

多くのコマンド（`click`, `fill`, `select`, `press` 等）が `--snapshot-after` オプションをサポートしている。操作→snapshot の2コマンドを1コマンドに集約でき、操作と結果確認の間のタイミング問題も回避できる。Phase 1 で確認する計画は含まれているが、Phase 2 以降のコマンド例にも積極的に取り入れるとよい:

```bash
# Before: 2コマンド
cmux browser $SURFACE click --selector "button"
cmux browser $SURFACE snapshot --interactive

# After: 1コマンド
cmux browser $SURFACE click --selector "button" --snapshot-after
```

### R2: メインオーケストレータスクリプトの追加

`scripts/` に個別スクリプト6本 + ヘルパー2本が計画されているが、それらを統合するメインスクリプト（例: `scripts/create-bot-main.sh`）が成果物に含まれていない。SKILL.md にフロー記述はあるが、エンドツーエンドで実行するスクリプトがないと、完了条件の「`/create-bot TestBot` で全フローが動作する」を満たすためのブリッジが不明確。Claude が SKILL.md を読んで逐次実行する想定であれば、その旨を明記すべき

### R3: `find` コマンドの `--name` パラメータの検証

計画書で `cmux browser $SURFACE find role button --name "New Application"` と使用しているが、コマンドリファレンスの `find` は `find <role|text|label|placeholder|alt|title|testid|first|last|nth> [...]` と記載されており、`--name` パラメータの存在が確認できない。Phase 1 で `find` コマンドの利用可能なオプションを確認する検証項目を追加すべき

### R4: Phase 2 で「Bot は自動生成済み」のケースへの対応

Phase 2.2 に「2024年以降、Bot はアプリケーション作成時に自動生成される」と記載がある。これは重要な情報だが、計画書の Bot 設定ページのフローは「Add Bot ボタンがない」前提で書かれている一方、SKILL.md には「Add Bot → 確認ダイアログ」のステップが残っている。Phase 2 の手動検証で実際のフローを確認した後、SKILL.md の更新対象にこの差分解消を含めることを推奨

### R5: Phase 間の実験記録フォーマット

Phase 1-2 は探索的作業だが、各実験の結果を記録するフォーマットが定義されていない。例えば `runs/` ディレクトリに実験ログを残す方式を決めておくと、Phase 3 でのスクリプト化がスムーズになる。最低限、以下を記録する仕組みがあるとよい:
- 実行したコマンドと結果（成功/失敗）
- 発見したセレクタ
- 想定と異なった挙動

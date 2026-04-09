# Design Review (Rev2): plan.md

## 判定: Approved

## 前回 Issue の解消状況

| Issue | 状態 | コメント |
|---|---|---|
| 1. `grep -oP` は macOS で動作しない | 解消 | `sed -n 's\|.*/applications/\([0-9]*\).*\|\1\|p'` に変更済み。bash パラメータ展開の代替案も注記されている（L265-271） |
| 2. Intent トグルに `check`/`uncheck` を使うべき | 解消 | 全 Intent トグル操作が `check` に変更済み（L343-345）。冪等性の説明（L355）と Phase 1 完了条件への `check`/`uncheck` 冪等性確認の追加（L137）も適切 |
| 3. 条件なし `wait --timeout` の多用 | 解消 | 全 `wait` が条件付き（`--load-state`, `--selector`, `--url-contains`, `--text`）に変更済み。Phase 1 完了条件に「条件なし `wait --timeout` と条件付き `wait` の動作差分確認」を追加（L135）し、動作不明な点を実験で解消する方針が明確 |
| 4. トークン取得時の snapshot による漏洩リスク | 解消 | `get value`/`get text` でのピンポイント取得に変更（L308-311）。トークン表示中の `snapshot`/`screenshot` 禁止を明記（L303, L329-330）。取得後のページ遷移（L321）、`umask 077` によるファイル保存（L325）、文字数のみの通知（L318, L333）が追加されている |

## 前回 Recommendation の対応状況

| Recommendation | 対応 | コメント |
|---|---|---|
| R1: `--snapshot-after` の積極活用 | 対応済み | Phase 2 の各ステップで `--snapshot-after` が積極的に使用されている（L225, L236, L245, L343-348, L377-394 等） |
| R2: メインオーケストレータスクリプト追加 | 対応済み | `scripts/create-bot-main.sh` が成果物に追加（L463-506, L637）。引数パース、フェーズ間の値受け渡し、オプションのサーバー招待を含む。Claude 逐次実行との代替案も明記（L506） |
| R3: `find --name` パラメータの検証を Phase 1 に追加 | 対応済み | Phase 1 完了条件に追加（L136） |
| R4: SKILL.md の Add Bot 差分解消 | 対応済み | Phase 3 の SKILL.md 更新項目に明記（L538）。完了条件にも反映（L681） |
| R5: 実験記録フォーマット | 対応済み | Phase 1-2 共通のフォーマットを定義（L139-177）。ファイル命名規則、テンプレート、スクリーンショット保存先が具体的に記載されている |

## 新たな指摘（あれば）

- 重大な問題は発見されなかった。前回指摘した4つの Issue はすべて適切に解消されており、5つの Recommendation もすべて反映されている。計画書として十分な品質であり、Phase 1 の実行に進んでよい。

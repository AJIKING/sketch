---
description: 現在の差分をハーネス方針・品質ゲートと照合してレビューする
---

現在の差分(unstaged + staged。引数で PR 番号やブランチが指定されたらそれ)を `docs/harness-engineering.md` の方針と照合してレビューする。レビュー本体は `harness-reviewer` サブエージェントに委譲してよい。

対象: $ARGUMENTS

チェック観点:

1. **品質ゲート**: format / analyze / unit / widget test が通るか。意図しない golden 差分が混ざっていないか。
2. **テストの層**: 変更に見合う層のテストがあるか(ロジック→unit、UI 分岐→widget、共有コンポーネントの見た目→golden)。integration でしか守られていないロジックがないか。
3. **決定性**: 実時間(`DateTime.now()` 直叩き)、実通信、グローバル状態、`sleep`/`Future.delayed` ベースの同期など、flaky の種が増えていないか。差し替え境界(`Clock`, `ApiClient`, `LocalStore` 等)を迂回していないか。
4. **fixture**: 本番データ snapshot を持ち込んでいないか。fixture の命名が「検証したい振る舞い」になっているか。
5. **テストの削除・skip**: 理由と issue link のない削除・skip・timeout 延長がないか。
6. **CI**: `.github/workflows/` への変更がローカルコマンドと乖離していないか。
7. **依存ルール**(`docs/architecture.md`): `lib/src/domain/` に `package:flutter` の import がないか。`lib/src/ui/` から `data/` を直接 import していないか。境界インターフェースの変更時に本番実装と fake の両方が更新されているか。

出力: 指摘を「ブロッカー(品質ゲート違反)」「推奨(方針からの逸脱)」「メモ」の 3 段階で報告する。問題がなければ問題ないと明言する。

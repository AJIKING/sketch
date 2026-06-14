---
description: flaky test を triage する(原因分類 → 修正 or issue link 付き quarantine)
---

指定された flaky test を `docs/harness-engineering.md` の「Flaky Test ポリシー」に従って triage する。調査が重い場合は `flaky-triager` サブエージェントに委譲してよい。

対象テスト・失敗ログ: $ARGUMENTS

手順:

1. 対象テストのコードと、可能なら失敗ログ・artifact を読む。
2. 同じテストを複数回実行して再現性を確認する(例: `flutter test <path> --reporter expanded` を数回)。
3. 原因を次のいずれかに分類する: app race / test race / device instability / network dependency / timeout / animation / clock / platform behavior。
4. 対応を提案・実施する:
   - 根本修正できるなら修正する(sleep ではなく明示的な同期、実時間ではなく fake clock、実通信ではなく fake、など)。
   - すぐ直せないなら issue link 付きで quarantine する(`skip` に理由と issue URL を必ず併記)。

禁止事項:

- 理由を残さずテストを削除すること。
- 最初の対応として timeout を伸ばすこと。
- issue link なしの skip。

最後に、分類・対応内容・残タスク(quarantine 解除条件)を報告する。

---
description: CI 相当のチェック(format / analyze / test)をローカルで一括実行する
allowed-tools: Bash(flutter:*), Bash(dart:*), PowerShell(flutter:*), PowerShell(dart:*)
---

CI(`.github/workflows/check.yml`)と同じチェックをローカルで実行し、結果を報告する。

実行手順(CI と同じ順序・同じコマンドを使うこと):

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test --reporter expanded`

ルール:

- 途中で失敗しても可能な限り後続ステップも実行し、失敗を一覧で報告する。
- format 失敗は `dart format .` を適用して再チェックしてよい(対象ファイルを報告する)。
- analyze / test の失敗は勝手に修正せず、失敗内容・該当ファイル・原因の見立てを報告する。修正は指示があってから行う。
- 最後に「PR を出せる状態か」を一行で判定する。

追加の引数(対象パスなど): $ARGUMENTS

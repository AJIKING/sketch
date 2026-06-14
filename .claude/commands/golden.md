---
description: golden test を検証し、意図した UI 変更なら golden を更新する
allowed-tools: Bash(flutter:*), PowerShell(flutter:*), Read, Glob, Grep
---

golden test の検証・更新を行う。方針は `docs/harness-engineering.md` の「Golden Test 方針」に従う。

手順:

1. `flutter test test/golden` を実行する(`test/golden/` が無い・空の場合はその旨を報告して終了)。
2. 失敗した場合、差分の原因を調査する:
   - 直近の差分(git diff)に UI 変更が含まれるか確認する。
   - **意図した UI 変更による差分**であれば `flutter test --update-goldens test/golden` で更新し、更新された golden ファイルの一覧を報告する。
   - **意図しない差分**(UI 変更のない PR で golden が割れた等)であれば更新せず、回帰として原因ファイルと見立てを報告する。
3. 判断がつかない場合は更新せず、差分内容を説明してユーザーに確認する。

ルール:

- golden は視覚契約。失敗を黙らせるために無条件で `--update-goldens` を実行しない。
- 新しい golden test を書くときは device size / text scale / theme / locale / font loading を固定する。

対象(任意): $ARGUMENTS

# golden baselines

このディレクトリには golden の基準画像(`*.png`)を置く。

**まだ baseline は未生成。** golden 画像は platform 依存のため、基準は Linux に
固定する(ADR 0002 / `docs/design-docs/0002-golden-test-operations.md`)。生成手順:

1. `.github/workflows/golden.yml` を workflow_dispatch で実行する(ubuntu-latest 上で
   `flutter test --update-goldens test/golden`)。
2. artifact `golden-baselines` をダウンロードする。
3. 中身をこのディレクトリに展開してコミットする。

baseline をコミットするまで、CI の `golden` job(`flutter test --tags golden`)は
赤になる。これは bootstrap 中の想定状態で、ローカルの `flutter test` と check.yml の
test ステップ(`--exclude-tags golden`)は緑のまま。**Windows / macOS で
`--update-goldens` した画像はコミットしない。**

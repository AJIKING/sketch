# Hatch — ポケットのアトリエ(sketch)

スマホで完結する軽量スケッチ/お絵描き Flutter アプリ。レイヤー・ブラシ・カラーピッカーを備えた「ポケットのアトリエ」。オフライン完結・バックエンドなし。

## ドキュメント

- 仕様: [docs/product-spec.md](docs/product-spec.md)(プロトタイプ: [docs/prototype/hatch-sketch-app.html](docs/prototype/hatch-sketch-app.html))
- アーキテクチャ: [docs/architecture.md](docs/architecture.md)
- テスト計画: [docs/test-plan.md](docs/test-plan.md)
- ハーネス方針: [docs/harness-engineering.md](docs/harness-engineering.md)

## セットアップ

Flutter SDK は **3.44.1**(`.fvmrc` で固定。CI と同一バージョン)。FVM がある環境では `fvm flutter ...`、なければ `flutter` を直接使う。

```sh
flutter pub get
```

## 開発コマンド

CI(`.github/workflows/check.yml`)と同じチェック(`/check` で一括実行可):

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --reporter expanded
```

golden の更新(基準 platform = Linux 上でのみ実行。詳細はハーネス方針の Golden 節 / ADR 0002):

```sh
flutter test --update-goldens test/golden
```

integration smoke test(エミュレータ / シミュレータを起動してから実行。CI では `.github/workflows/integration.yml` が main push 時に実行):

```sh
flutter test integration_test -d <device-id>
```
